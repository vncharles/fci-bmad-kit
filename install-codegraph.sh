#!/usr/bin/env bash
#
# FCI BMad Kit — setup Codegraph MCP (@optave/codegraph). Standalone HOẶC source được.
#
# Dùng @optave/codegraph (https://github.com/optave/ops-codegraph-tool) — hỗ trợ MULTI-REPO
# native: build từng repo (tự đăng ký vào registry chung), rồi chạy MỘT MCP server
# `codegraph mcp --multi-repo` phục vụ tất cả repo (mọi tool có thêm param `repo`).
#
# Hai cách dùng:
#   1) Standalone (single-repo, tương thích ngược):
#        ./install-codegraph.sh
#        TARGET_DIR=/path/to/project ./install-codegraph.sh
#      → build repo + add MCP server "codegraph" (single-repo mode) cho TARGET_DIR.
#
#   2) Source làm thư viện (dùng bởi init-workspace.sh cho multi-repo):
#        source install-codegraph.sh
#        cg_require_node
#        cg_install_cli
#        setup_codegraph_for_repo "/abs/path/to/repo" "<registry-name>"   # build + register
#        register_multirepo_mcp                                            # 1 MCP cho cả workspace
#
# Mọi giá trị dưới đây đều override được bằng biến môi trường.

set -euo pipefail

CODEGRAPH_PKG="${CODEGRAPH_PKG:-@optave/codegraph}"   # npm package cung cấp bin `codegraph`
EMBED_PKG="${EMBED_PKG:-@huggingface/transformers}"  # engine cho `codegraph embed` (semantic search)
EMBED_MODEL="${EMBED_MODEL:-jina-code}"              # model embed mặc định (code-aware). Đặt rỗng để bỏ embed.
EMBED_STRATEGY="${EMBED_STRATEGY:-structured}"       # structured | source

# ── Preflight: cần Node (để cài codegraph qua npm) ──────────────────────────────
# QUAN TRỌNG: better-sqlite3 trong @optave/codegraph là prebuilt cho Node 22.
# Cài Node 20 → lỗi runtime "NODE_MODULE_VERSION 115 vs 108" khi chạy embed/sqlite.
AUTO_INSTALL_NODE="${AUTO_INSTALL_NODE:-1}"   # 1 = tự cài Node qua nvm nếu thiếu/cũ
NODE_VERSION="${NODE_VERSION:-22}"            # major version Node muốn cài (phải khớp prebuilt sqlite = 22)
NVM_VERSION="${NVM_VERSION:-v0.40.1}"         # tag nvm dùng để bootstrap

cg_node_ok() {
  command -v node >/dev/null 2>&1 || return 1
  local v major
  v="$(node -p 'process.versions.node' 2>/dev/null)" || return 1
  major="${v%%.*}"
  [ "$major" -ge 22 ]
}

cg_bootstrap_node_via_nvm() {
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

cg_require_node() {
  if cg_node_ok; then return 0; fi
  if command -v node >/dev/null 2>&1; then
    echo "✗ Node $(node -p 'process.versions.node') không khớp — cần Node >=22 (prebuilt sqlite của codegraph)." >&2
  else
    echo "✗ Máy chưa cài Node — codegraph cần Node để cài qua npm." >&2
  fi
  if [ "$AUTO_INSTALL_NODE" != "1" ]; then
    echo "  Khắc phục: cài Node >=20.12 rồi chạy lại, hoặc AUTO_INSTALL_NODE=1 để tự cài." >&2
    exit 1
  fi
  echo "▶ AUTO_INSTALL_NODE=1 — đang tự cài Node $NODE_VERSION qua nvm..."
  cg_bootstrap_node_via_nvm
  cg_node_ok || { echo "✗ Vẫn chưa có Node hợp lệ. Mở terminal mới, 'nvm use $NODE_VERSION' rồi thử lại." >&2; exit 1; }
}

# ── Cài codegraph CLI (@optave/codegraph) ───────────────────────────────────────
cg_install_cli() {
  # Gỡ bin `codegraph` cũ (package unscoped khác) nếu có — tránh xung đột tên bin.
  if npm ls -g codegraph >/dev/null 2>&1; then
    echo "  • Gỡ package 'codegraph' cũ (xung đột bin) — npm uninstall -g codegraph"
    npm uninstall -g codegraph || true
  fi
  # Cài đúng phiên bản @optave nếu chưa có hoặc đang là bin khác.
  if codegraph --version >/dev/null 2>&1 && npm ls -g "$CODEGRAPH_PKG" >/dev/null 2>&1; then
    echo "  ✓ codegraph ($CODEGRAPH_PKG) đã có: $(codegraph --version 2>&1 | head -n1)"
  else
    echo "  • Cài codegraph: npm install -g $CODEGRAPH_PKG"
    npm install -g "$CODEGRAPH_PKG"
  fi
}

# ── Cài engine embed (@huggingface/transformers) ở GLOBAL ───────────────────────
# Bắt buộc TRƯỚC khi `codegraph embed`. Nếu thiếu, codegraph tự `npm install` vào
# cwd = repo → đẻ node_modules/package.json RÁC trong repo. Cài global để tránh.
cg_install_engine() {
  [ -z "$EMBED_MODEL" ] && return 0   # bỏ embed → khỏi cần engine
  if npm ls -g "$EMBED_PKG" >/dev/null 2>&1; then
    echo "  ✓ engine embed ($EMBED_PKG) đã có (global)."
  else
    echo "  • Cài engine embed: npm install -g $EMBED_PKG"
    npm install -g "$EMBED_PKG" --legacy-peer-deps \
      || echo "    ⚠ Cài '$EMBED_PKG' lỗi — embed sẽ bị bỏ qua."
  fi
}

# ── Build index cho MỘT repo + (tuỳ chọn) embed + đăng ký vào registry chung ─────
# setup_codegraph_for_repo <abs-repo-path> [registry-name]
setup_codegraph_for_repo() {
  local repo_path="$1"
  local name="${2:-$(basename "$repo_path")}"

  echo "▶ Codegraph build cho repo: $repo_path  (registry name: $name)"
  # build tự đăng ký project vào registry chung; chỉ định tên cho chắc chắn.
  codegraph build "$repo_path" || echo "    ⚠ codegraph build lỗi — bỏ qua."
  codegraph registry add "$repo_path" -n "$name" \
    || echo "    ⚠ registry add '$name' (có thể đã tồn tại) — bỏ qua."
  cg_embed_repo "$repo_path"
}

# ── Embed semantic cho MỘT repo (cần engine + đã build) ──────────────────────────
# Luôn truyền --db tuyệt đối: `codegraph embed <dir>` KHÔNG dùng dir cho path DB,
# nó đọc .codegraph/graph.db ở CWD nếu thiếu --db.
cg_embed_repo() {
  local repo_path="$1"
  [ -z "$EMBED_MODEL" ] && { echo "    • EMBED_MODEL rỗng — bỏ qua embed."; return 0; }
  local db="$repo_path/.codegraph/graph.db"
  [ -f "$db" ] || { echo "    ⚠ Chưa có $db — bỏ qua embed (build lỗi?)."; return 0; }
  echo "    • Embed ($EMBED_MODEL / $EMBED_STRATEGY): $repo_path"
  codegraph embed "$repo_path" --db "$db" --model "$EMBED_MODEL" --strategy "$EMBED_STRATEGY" \
    || echo "    ⚠ codegraph embed lỗi — semantic search sẽ không có (graph vẫn dùng được)."
}

# ── Đăng ký MỘT MCP server multi-repo cho cả workspace ──────────────────────────
# Đường dẫn TUYỆT ĐỐI tới bin codegraph (ghim node 22) — tránh MCP gãy khi default node đổi.
cg_bin_path() { command -v codegraph 2>/dev/null || echo codegraph; }

register_multirepo_mcp() {
  local cg; cg="$(cg_bin_path)"
  if command -v claude >/dev/null 2>&1; then
    echo "  • claude mcp add codegraph (multi-repo) → $cg"
    claude mcp remove codegraph >/dev/null 2>&1 || true   # xoá entry cũ (single-mode) nếu có
    claude mcp add codegraph -- "$cg" mcp --multi-repo \
      || echo "    ⚠ Không add được MCP 'codegraph'. Chạy thủ công: claude mcp add codegraph -- $cg mcp --multi-repo"
  else
    echo "  ⚠ Không tìm thấy CLI 'claude' — bỏ qua bước add MCP."
    echo "    Chạy thủ công sau: claude mcp add codegraph -- $cg mcp --multi-repo"
  fi
}

# ── Đăng ký MCP single-repo (dùng cho standalone) ───────────────────────────────
register_singlerepo_mcp() {
  local cg; cg="$(cg_bin_path)"
  if command -v claude >/dev/null 2>&1; then
    echo "  • claude mcp add codegraph (single-repo) → $cg"
    claude mcp add codegraph -- "$cg" mcp \
      || echo "    ⚠ Không add được (có thể đã tồn tại). Bỏ qua."
  else
    echo "  ⚠ Không tìm thấy CLI 'claude' — bỏ qua bước add MCP."
    echo "    Chạy thủ công sau: claude mcp add codegraph -- $cg mcp"
  fi
}

# ── Main: chỉ chạy khi gọi trực tiếp (không chạy khi được `source`) ──────────────
cg_main() {
  TARGET_DIR="${TARGET_DIR:-.}"
  local project_path
  project_path="$(cd "$TARGET_DIR" && pwd)"

  cg_require_node
  echo "▶ Setup Codegraph MCP cho: $project_path"
  cg_install_cli
  cg_install_engine
  setup_codegraph_for_repo "$project_path"
  register_singlerepo_mcp

  echo
  echo "✓ Codegraph setup xong."
}

# BASH_SOURCE[0] == $0 nghĩa là file đang được thực thi trực tiếp, không phải source.
if [ "${BASH_SOURCE[0]:-}" = "${0}" ]; then
  cg_main
fi
