#!/usr/bin/env bash
#
# FCI BMad Kit — khởi tạo / tham gia MULTI-REPO WORKSPACE (team-based).
#
# Đội vận hành là NGƯỜI THẬT: PO, BA, Dev, Tester — mỗi người một máy, chỉ dùng agent của mình.
# Điều phối giữa các vai diễn ra QUA GIT trên repo "docs" chung:
#   - repo "docs"   : hub chia sẻ — chứa workspace.yml, handoff/, prd/epics/stories/tasks/test-plans.
#                     BẮT BUỘC, clone đầu tiên, tên cố định "docs", KHÔNG codegraph.
#   - các app repo  : code (octavia, octavia-dashboard, ...) — build codegraph, đăng ký vào
#                     registry chung của @optave/codegraph, dùng chung 1 MCP `codegraph mcp --multi-repo`.
#
# Clone theo ROLE:
#   - PO            : chỉ clone docs (PO làm product-level, không đọc code).
#   - BA/Dev/Tester : clone docs + (các) app repo + build codegraph.
#
# workspace.yml nằm TRONG repo docs (docs/workspace.yml) = danh sách repo chuẩn của dự án,
# share cho cả đội qua git. Người đầu tiên "khai báo" repo; người sau "tham gia" bằng cách
# clone docs rồi chọn app repo cần.
#
# Dùng (chạy LOCAL, tương tác):
#   ./init-workspace.sh
#   TARGET_DIR=/path/to/workspace ROLE=dev ./init-workspace.sh
#
# Yêu cầu: đã login GitLab sẵn (SSH key / credential helper) — script chỉ `git clone`/`git pull`.

set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ── Lựa chọn ─────────────────────────────────────────────────────────────────────
TARGET_DIR="${TARGET_DIR:-.}"
WORKSPACE_ROOT="$(cd "$TARGET_DIR" && pwd)"
WORKSPACE_NAME="${WORKSPACE_NAME:-$(basename "$WORKSPACE_ROOT")}"
DOCS_DIR_NAME="docs"
DOCS_PATH="$WORKSPACE_ROOT/$DOCS_DIR_NAME"
REG="$DOCS_PATH/workspace.yml"                  # registry NẰM TRONG repo docs
HANDOFF_REL="docs/handoff"                       # handoff cũng nằm trong repo docs
ROLE="${ROLE:-}"                                 # po | ba | dev | tester
SETUP_BMAD="${SETUP_BMAD:-1}"

# Đọc input tương tác (mở TTY một lần trên fd 3; FCI_TTY override chỉ để test).
TTY="${FCI_TTY:-/dev/tty}"
if : <"$TTY" 2>/dev/null; then exec 3<"$TTY"; else exec 3<&0; fi
ask() {
  local prompt="$1" def="${2:-}" reply
  if [ -n "$def" ]; then prompt="$prompt [$def]"; fi
  printf "%s: " "$prompt" >&2
  IFS= read -r reply <&3 || reply=""
  echo "${reply:-$def}"
}
ask_yn() {
  local prompt="$1" def="${2:-y}" reply
  reply="$(ask "$prompt (y/n)" "$def")"
  case "$reply" in y|Y|yes|YES) return 0 ;; *) return 1 ;; esac
}

# ── Registry helpers (workspace.yml trong repo docs) ─────────────────────────────
reg_init_if_missing() {
  [ -f "$REG" ] && return 0
  cat > "$REG" <<EOF
# FCI multi-repo workspace registry — share qua repo docs. Sinh/cập nhật bởi init-workspace.sh.
workspace:
  name: $WORKSPACE_NAME
  created: $(date +%Y-%m-%d)
  docs_repo: $DOCS_DIR_NAME
  handoff_folder: $HANDOFF_REL
  # @optave/codegraph: 1 MCP "codegraph" chạy --multi-repo phục vụ mọi app repo.
  # Agent gọi tool codegraph và truyền param repo = <registry_name> của repo đang làm.
  codegraph_mcp: codegraph
  codegraph_mode: multi-repo
repos:
  - name: $DOCS_DIR_NAME
    url: __SET_BY_CLONE__
    branch: __SET_BY_CLONE__
    type: docs
    codegraph: false
EOF
}

# In ra TSV "name<TAB>url<TAB>branch<TAB>codegraph" cho repo type=app (dùng python cho chắc).
reg_list_app_repos() {
  python3 - "$REG" <<'PY'
import sys, yaml
d = yaml.safe_load(open(sys.argv[1])) or {}
for r in (d.get("repos") or []):
    if r.get("type") == "app":
        print(f"{r.get('name','')}\t{r.get('url','')}\t{r.get('branch','')}\t{r.get('codegraph','')}")
PY
}

reg_has_repo() {  # reg_has_repo <name> -> 0 nếu có
  python3 - "$REG" "$1" <<'PY'
import sys, yaml
d = yaml.safe_load(open(sys.argv[1])) or {}
sys.exit(0 if any((r.get("name")==sys.argv[2]) for r in (d.get("repos") or [])) else 1)
PY
}

reg_set_docs_origin() {  # điền url/branch thực tế cho entry docs (text-replace, giữ comment + indent)
  local url="$1" branch="$2"
  python3 - "$REG" "$url" "$branch" <<'PY'
import sys
p, url, branch = sys.argv[1], sys.argv[2], sys.argv[3]
s = open(p).read()
s = s.replace("url: __SET_BY_CLONE__", "url: " + url, 1)
s = s.replace("branch: __SET_BY_CLONE__", "branch: " + branch, 1)
open(p, "w").write(s)
PY
}

reg_add_app_repo() {  # reg_add_app_repo <name> <url> <branch>
  local name="$1" url="$2" branch="$3"
  {
    echo "  - name: $name"
    echo "    url: $url"
    echo "    branch: $branch"
    echo "    type: app"
    echo "    codegraph: true"
    echo "    registry_name: $name"
  } >> "$REG"
}

# ── Git helpers ──────────────────────────────────────────────────────────────────
# Gọi như STATEMENT thường (KHÔNG trong $()), để lỗi clone không bị set -e nuốt.
# Trả non-zero nếu clone thất bại → caller skip mềm repo đó.
git_clone_or_pull() {  # git_clone_or_pull <url> <branch> <dest-name>
  local url="$1" branch="$2" dest="$WORKSPACE_ROOT/$3"
  if [ -d "$dest/.git" ]; then
    echo "  • '$3' đã có — git pull --ff-only"
    git -C "$dest" pull --ff-only || echo "    ⚠ pull lỗi/conflict — kiểm tra thủ công."
    return 0
  fi
  echo "  • git clone $url → $3 (branch: ${branch:-default})"
  if [ -n "$branch" ]; then
    git clone --branch "$branch" "$url" "$dest" || { echo "  ✗ Clone '$url' (branch $branch) thất bại."; return 1; }
  else
    git clone "$url" "$dest" || { echo "  ✗ Clone '$url' thất bại."; return 1; }
  fi
}
current_branch() { git -C "$WORKSPACE_ROOT/$1" rev-parse --abbrev-ref HEAD 2>/dev/null || echo "?"; }

# ── Bắt đầu ──────────────────────────────────────────────────────────────────────
echo "▶ FCI workspace: $WORKSPACE_NAME   (root = $WORKSPACE_ROOT)"

# Role → quyết định có clone code + codegraph không. Hỏi bằng menu nếu chưa set qua env.
if [ -z "$ROLE" ]; then
  {
    echo "  Bạn là vai trò nào?"
    echo "    1) PO     — Product Owner   (chỉ clone docs)"
    echo "    2) BA     — Business Analyst (docs + code + codegraph)"
    echo "    3) Dev    — Developer        (docs + code + codegraph)"
    echo "    4) Tester — QA Tester        (docs + code + codegraph)"
  } >&2
  while :; do
    sel="$(ask "Chọn (1-4)" "")"
    case "$sel" in
      1|po|PO)         ROLE=po; break ;;
      2|ba|BA)         ROLE=ba; break ;;
      3|dev|DEV)       ROLE=dev; break ;;
      4|tester|TESTER) ROLE=tester; break ;;
      *) echo "    ⚠ Nhập 1, 2, 3 hoặc 4." >&2 ;;
    esac
  done
fi
ROLE="$(echo "$ROLE" | tr '[:upper:]' '[:lower:]')"
case "$ROLE" in
  po)            CLONE_CODE=0 ;;
  ba|dev|tester) CLONE_CODE=1 ;;
  *) echo "  ⚠ Role '$ROLE' không rõ — coi như có clone code."; CLONE_CODE=1 ;;
esac
echo "  • Role: $ROLE  → $([ "$CLONE_CODE" = 1 ] && echo 'clone docs + app repo + codegraph' || echo 'chỉ clone docs')"

# ── [1] Repo docs (bắt buộc) ─────────────────────────────────────────────────────
echo
echo "── [1] Repo DOCS (hub chia sẻ: workspace.yml + handoff + prd/epics/stories/...) ──"
if [ -d "$DOCS_PATH/.git" ]; then
  git_clone_or_pull "" "" "$DOCS_DIR_NAME" || true
  docs_url="$(git -C "$DOCS_PATH" remote get-url origin 2>/dev/null || echo '')"
else
  docs_url="$(ask "GitLab URL cho repo docs" "")"
  [ -z "$docs_url" ] && { echo "✗ Bắt buộc có repo docs. Dừng." >&2; exit 1; }
  docs_branch_in="$(ask "Branch repo docs" "main")"
  git_clone_or_pull "$docs_url" "$docs_branch_in" "$DOCS_DIR_NAME" \
    || { echo "✗ Clone docs thất bại. Dừng." >&2; exit 1; }
fi
docs_branch="$(current_branch "$DOCS_DIR_NAME")"
reg_init_if_missing
reg_set_docs_origin "$docs_url" "$docs_branch"
mkdir -p "$DOCS_PATH/handoff"
echo "  ✓ docs sẵn sàng (branch: $docs_branch). Registry: $REG"

# ── [2] Codegraph CLI (chỉ khi cần clone code) ───────────────────────────────────
if [ "$CLONE_CODE" = 1 ]; then
  echo
  echo "── [2] Chuẩn bị Codegraph (@optave/codegraph) ──"
  # shellcheck disable=SC1091
  source "$HERE/install-codegraph.sh"
  cg_require_node
  cg_install_cli
  cg_install_engine   # engine embed ở global → tránh codegraph đẻ node_modules rác vào repo
fi

# ── [3] App repo: clone repo đã khai báo trong registry + khai báo repo mới ───────
echo
echo "── [3] App repo (code) ──"
APP_BUILT=0

# (a) Các repo đã có trong registry (do đồng đội khai báo trước) → chọn clone.
if [ "$CLONE_CODE" = 1 ]; then
  while IFS=$'\t' read -r name url branch _; do
    [ -z "$name" ] && continue
    if [ -d "$WORKSPACE_ROOT/$name/.git" ]; then continue; fi
    if ask_yn "Registry có repo '$name' — clone về máy?" "y"; then
      if git_clone_or_pull "$url" "$branch" "$name"; then
        setup_codegraph_for_repo "$WORKSPACE_ROOT/$name" "$name"
        APP_BUILT=$((APP_BUILT+1))
        echo "  ✓ '$name' (branch: $(current_branch "$name"))"
      else
        echo "  ⚠ Bỏ qua '$name' do clone lỗi."
      fi
    fi
  done < <(reg_list_app_repos)
fi

# (b) Khai báo repo mới (mọi role được khai báo; PO chỉ ghi registry, không clone).
while ask_yn "Khai báo thêm một app repo mới vào dự án?" "$([ "$APP_BUILT" = 0 ] && echo y || echo n)"; do
  name="$(ask "Tên repo (vd octavia)" "")"
  [ -z "$name" ] && { echo "  ⚠ Tên rỗng — bỏ qua."; continue; }
  [ "$name" = "$DOCS_DIR_NAME" ] && { echo "  ⚠ 'docs' là tên dành riêng."; continue; }
  if reg_has_repo "$name"; then echo "  ⚠ '$name' đã có trong registry."; else
    url="$(ask "GitLab URL cho '$name'" "")"
    [ -z "$url" ] && { echo "  ⚠ URL rỗng — bỏ qua."; continue; }
    branch="$(ask "Branch cho '$name'" "main")"
    reg_add_app_repo "$name" "$url" "$branch"
    echo "  ✓ Đã ghi '$name' vào registry."
    if [ "$CLONE_CODE" = 1 ]; then
      if git_clone_or_pull "$url" "$branch" "$name"; then
        setup_codegraph_for_repo "$WORKSPACE_ROOT/$name" "$name"
        APP_BUILT=$((APP_BUILT+1))
        echo "  ✓ '$name' clone + build xong (branch: $(current_branch "$name"))"
      else
        echo "  ⚠ '$name' đã ghi registry nhưng clone lỗi — clone lại sau."
      fi
    else
      echo "  • Role $ROLE: chỉ khai báo, không clone code."
    fi
  fi
done

# Một MCP multi-repo cho cả workspace (nếu đã build ít nhất 1 repo).
if [ "$APP_BUILT" -gt 0 ]; then
  echo
  echo "── Đăng ký MCP codegraph (multi-repo) ──"
  register_multirepo_mcp
fi

# ── [4] Cài BMad ở workspace root (artifacts + handoff → repo docs) ───────────────
if [ "$SETUP_BMAD" = 1 ]; then
  echo
  echo "── [4] Cài BMad ở workspace root ──"
  TARGET_DIR="$WORKSPACE_ROOT" \
  HANDOFF_FOLDER="{project-root}/$HANDOFF_REL" \
  PROJECT_KNOWLEDGE="{project-root}/$DOCS_DIR_NAME" \
  PLANNING_ARTIFACTS="{project-root}/$DOCS_DIR_NAME" \
  IMPL_ARTIFACTS="{project-root}/$DOCS_DIR_NAME" \
  WORKSPACE_FILE_REL="$DOCS_DIR_NAME/workspace.yml" \
    bash "$HERE/install-bmad.sh"
fi

# ── [5] Đẩy registry + handoff mới lên repo docs cho cả đội (bán tự động) ─────────
echo
echo "── [5] Đồng bộ registry lên repo docs ──"
if [ -n "$(git -C "$DOCS_PATH" status --porcelain 2>/dev/null)" ]; then
  if ask_yn "Commit & push workspace.yml lên repo docs cho đội?" "y"; then
    git -C "$DOCS_PATH" add -A
    git -C "$DOCS_PATH" commit -m "chore(workspace): update registry via init-workspace" >&2 || true
    git -C "$DOCS_PATH" push >&2 || echo "  ⚠ push lỗi — kiểm tra quyền/branch." >&2
  else
    echo "  • Bỏ qua. Nhớ tự: git -C docs add -A && git -C docs commit && git -C docs push"
  fi
fi

echo
echo "✓ Workspace '$WORKSPACE_NAME' sẵn sàng (role: $ROLE)."
echo "  • Registry : $REG"
echo "  • Handoff  : $DOCS_PATH/handoff/"
if command -v claude >/dev/null 2>&1 && [ "$APP_BUILT" -gt 0 ]; then
  echo "  • MCP:"; claude mcp list 2>/dev/null | grep -i codegraph || true
fi
echo "  • Mở Claude Code tại workspace root, dùng agent của role bạn: /fci-po /fci-ba /fci-dev /fci-tester"
