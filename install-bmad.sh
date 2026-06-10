#!/usr/bin/env bash
#
# FCI BMad Kit — cài BMad (non-interactive). Standalone, chạy độc lập được.
#
# Bỏ qua phần hỏi-đáp của `npx bmad-method install`. Cài sẵn:
#   - bmm  (built-in BMad: bmad-prd, bmad-create-story, bmad-dev-story, ...)
#   - tea  (external: bmad-method-test-architecture-enterprise)
#   - fci  (module này, lấy từ git URL bên dưới)
# rồi cấu hình cho IDE claude-code.
#
# Dùng:
#   ./install-bmad.sh
#   TARGET_DIR=/path/to/project USER_NAME="Trong" ./install-bmad.sh
#
# Mọi giá trị dưới đây đều override được bằng biến môi trường.

set -euo pipefail

# ── Preflight: bmad-method 6.8+ cần Node >=20.12 (dùng node:util styleText) ─────
AUTO_INSTALL_NODE="${AUTO_INSTALL_NODE:-1}"   # 1 = tự cài Node qua nvm nếu thiếu/cũ
NODE_VERSION="${NODE_VERSION:-20}"            # major version Node muốn cài
NVM_VERSION="${NVM_VERSION:-v0.40.1}"         # tag nvm dùng để bootstrap

node_ok() {
  command -v node >/dev/null 2>&1 || return 1
  local v major rest minor
  v="$(node -p 'process.versions.node' 2>/dev/null)" || return 1
  major="${v%%.*}"; rest="${v#*.}"; minor="${rest%%.*}"
  [ "$major" -gt 20 ] || { [ "$major" -eq 20 ] && [ "$minor" -ge 12 ]; }
}

bootstrap_node_via_nvm() {
  # Nạp nvm nếu đã cài, hoặc cài mới vào $HOME (user-space, không cần sudo).
  export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
  if [ ! -s "$NVM_DIR/nvm.sh" ]; then
    echo "  • Chưa có nvm — cài nvm $NVM_VERSION vào $NVM_DIR"
    curl -fsSL "https://raw.githubusercontent.com/nvm-sh/nvm/${NVM_VERSION}/install.sh" | bash
  fi
  # shellcheck disable=SC1091
  \. "$NVM_DIR/nvm.sh"
  echo "  • nvm install $NODE_VERSION && nvm use $NODE_VERSION"
  nvm install "$NODE_VERSION"
  nvm use "$NODE_VERSION"
}

require_node() {
  if node_ok; then
    echo "  ✓ Node $(node -p 'process.versions.node') OK (>=20.12)"
    return 0
  fi

  if command -v node >/dev/null 2>&1; then
    echo "✗ Node $(node -p 'process.versions.node') quá cũ — cần >=20.12 (node:util thiếu 'styleText')." >&2
  else
    echo "✗ Máy chưa cài Node — bmad-method cần Node >=20.12." >&2
  fi

  if [ "$AUTO_INSTALL_NODE" != "1" ]; then
    echo "  Khắc phục: cài Node >=20.12 (vd: nvm install 20 && nvm use 20) rồi chạy lại," >&2
    echo "  hoặc chạy lại với AUTO_INSTALL_NODE=1 để script tự cài qua nvm." >&2
    exit 1
  fi

  echo "▶ AUTO_INSTALL_NODE=1 — đang tự cài Node $NODE_VERSION qua nvm..."
  bootstrap_node_via_nvm

  if node_ok; then
    echo "  ✓ Đã có Node $(node -p 'process.versions.node')"
  else
    echo "✗ Vẫn chưa có Node hợp lệ sau khi cài. Hãy mở terminal mới, chạy 'nvm use $NODE_VERSION' rồi thử lại." >&2
    exit 1
  fi
}
require_node

# ── Lựa chọn cài đặt (đã bake sẵn — sửa ở đây hoặc truyền qua env) ──────────────
TARGET_DIR="${TARGET_DIR:-.}"                                            # nơi cài
MODULES="${MODULES:-bmm,tea,fci}"                                        # module cần cài
TOOLS="${TOOLS:-claude-code}"                                            # IDE/tool
CUSTOM_SOURCE="${CUSTOM_SOURCE:-https://github.com/vncharles/fci-bmad-kit}"
CHANNEL="${CHANNEL:-stable}"                                             # stable | next
BMAD_VERSION="${BMAD_VERSION:-latest}"                                   # pin bmad-method nếu cần

# ── Cấu hình agent ─────────────────────────────────────────────────────────────
USER_NAME="${USER_NAME:-$(whoami)}"
COMM_LANG="${COMM_LANG:-Vietnamese}"                                     # ngôn ngữ giao tiếp
DOC_LANG="${DOC_LANG:-Vietnamese}"                                       # ngôn ngữ tài liệu xuất ra
OUTPUT_FOLDER="${OUTPUT_FOLDER:-_bmad-output}"
HANDOFF_FOLDER="${HANDOFF_FOLDER:-handoff}"                              # biến riêng của module fci

# ── Override path artifacts (chỉ dùng ở MULTI-REPO mode — để trống = giữ default BMad) ──
# init-workspace.sh set các biến này trỏ vào repo docs trung tâm.
PROJECT_KNOWLEDGE="${PROJECT_KNOWLEDGE:-}"     # vd "{project-root}/docs"
PLANNING_ARTIFACTS="${PLANNING_ARTIFACTS:-}"   # vd "{project-root}/docs"
IMPL_ARTIFACTS="${IMPL_ARTIFACTS:-}"           # vd "{project-root}/docs"
WORKSPACE_FILE_REL="${WORKSPACE_FILE_REL:-}"   # vd "workspace.yml" → fci.fci_workspace_file

echo "▶ Cài FCI BMad Kit (non-interactive)"
echo "  dir=$TARGET_DIR  modules=$MODULES  tools=$TOOLS  channel=$CHANNEL"
echo "  user=$USER_NAME  comm=$COMM_LANG  doc=$DOC_LANG  handoff=$HANDOFF_FOLDER"
if [ -n "$WORKSPACE_FILE_REL" ]; then echo "  workspace=$WORKSPACE_FILE_REL  knowledge=$PROJECT_KNOWLEDGE"; fi
echo

# Gom các --set tùy chọn (chỉ thêm khi biến không rỗng).
SET_ARGS=( --set "fci.fci_handoff_folder=$HANDOFF_FOLDER" )
if [ -n "$WORKSPACE_FILE_REL" ]; then SET_ARGS+=( --set "fci.fci_workspace_file={project-root}/$WORKSPACE_FILE_REL" ); fi
if [ -n "$PROJECT_KNOWLEDGE" ];  then SET_ARGS+=( --set "bmm.project_knowledge=$PROJECT_KNOWLEDGE" ); fi
if [ -n "$PLANNING_ARTIFACTS" ]; then SET_ARGS+=( --set "bmm.planning_artifacts=$PLANNING_ARTIFACTS" ); fi
if [ -n "$IMPL_ARTIFACTS" ];     then SET_ARGS+=( --set "bmm.implementation_artifacts=$IMPL_ARTIFACTS" ); fi

npx --yes "bmad-method@${BMAD_VERSION}" install \
  --yes \
  --directory "$TARGET_DIR" \
  --modules "$MODULES" \
  --tools "$TOOLS" \
  --custom-source "$CUSTOM_SOURCE" \
  --channel "$CHANNEL" \
  --user-name "$USER_NAME" \
  --communication-language "$COMM_LANG" \
  --document-output-language "$DOC_LANG" \
  --output-folder "$OUTPUT_FOLDER" \
  "${SET_ARGS[@]}"

echo
echo "✓ BMad đã cài xong. Dùng trong Claude Code: /fci-po  /fci-ba  /fci-dev  /fci-tester"

# ── Thêm các folder kit vào .git/info/exclude (local ignore, không ảnh hưởng team) ──
GIT_DIR="$(git -C "$TARGET_DIR" rev-parse --git-dir 2>/dev/null || true)"
if [ -n "$GIT_DIR" ]; then
  EXCLUDE_FILE="$GIT_DIR/info/exclude"
  mkdir -p "$(dirname "$EXCLUDE_FILE")"
  PATTERNS=("_bmad/" "_bmad-output/" ".claude/" ".codegraph/" ".agents/")
  ADDED=()
  for pat in "${PATTERNS[@]}"; do
    if ! grep -qxF "$pat" "$EXCLUDE_FILE" 2>/dev/null; then
      echo "$pat" >> "$EXCLUDE_FILE"
      ADDED+=("$pat")
    fi
  done
  if [ ${#ADDED[@]} -gt 0 ]; then
    echo "  • Đã thêm vào .git/info/exclude: ${ADDED[*]}"
  else
    echo "  • .git/info/exclude đã có đủ các pattern."
  fi
fi
