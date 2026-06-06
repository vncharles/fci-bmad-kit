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

# ── Preflight: cần Node (để cài codegraph qua npm) ──────────────────────────────
AUTO_INSTALL_NODE="${AUTO_INSTALL_NODE:-1}"   # 1 = tự cài Node qua nvm nếu thiếu/cũ
NODE_VERSION="${NODE_VERSION:-20}"            # major version Node muốn cài
NVM_VERSION="${NVM_VERSION:-v0.40.1}"         # tag nvm dùng để bootstrap

cg_node_ok() {
  command -v node >/dev/null 2>&1 || return 1
  local v major rest minor
  v="$(node -p 'process.versions.node' 2>/dev/null)" || return 1
  major="${v%%.*}"; rest="${v#*.}"; minor="${rest%%.*}"
  [ "$major" -gt 20 ] || { [ "$major" -eq 20 ] && [ "$minor" -ge 12 ]; }
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
    echo "✗ Node $(node -p 'process.versions.node') quá cũ — cần >=20.12." >&2
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

# ── Build index cho MỘT repo + đăng ký vào registry chung ────────────────────────
# setup_codegraph_for_repo <abs-repo-path> [registry-name]
setup_codegraph_for_repo() {
  local repo_path="$1"
  local name="${2:-$(basename "$repo_path")}"

  echo "▶ Codegraph build cho repo: $repo_path  (registry name: $name)"
  # build tự đăng ký project vào registry chung; chỉ định tên cho chắc chắn.
  codegraph build "$repo_path" || echo "    ⚠ codegraph build lỗi — bỏ qua."
  codegraph registry add "$repo_path" -n "$name" \
    || echo "    ⚠ registry add '$name' (có thể đã tồn tại) — bỏ qua."
}

# ── Đăng ký MỘT MCP server multi-repo cho cả workspace ──────────────────────────
register_multirepo_mcp() {
  if command -v claude >/dev/null 2>&1; then
    echo "  • claude mcp add codegraph (multi-repo)"
    claude mcp remove codegraph >/dev/null 2>&1 || true   # xoá entry cũ (single-mode) nếu có
    claude mcp add codegraph -- codegraph mcp --multi-repo \
      || echo "    ⚠ Không add được MCP 'codegraph'. Chạy thủ công: claude mcp add codegraph -- codegraph mcp --multi-repo"
  else
    echo "  ⚠ Không tìm thấy CLI 'claude' — bỏ qua bước add MCP."
    echo "    Chạy thủ công sau: claude mcp add codegraph -- codegraph mcp --multi-repo"
  fi
}

# ── Đăng ký MCP single-repo (dùng cho standalone) ───────────────────────────────
register_singlerepo_mcp() {
  if command -v claude >/dev/null 2>&1; then
    echo "  • claude mcp add codegraph (single-repo)"
    claude mcp add codegraph -- codegraph mcp \
      || echo "    ⚠ Không add được (có thể đã tồn tại). Bỏ qua."
  else
    echo "  ⚠ Không tìm thấy CLI 'claude' — bỏ qua bước add MCP."
    echo "    Chạy thủ công sau: claude mcp add codegraph -- codegraph mcp"
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
  setup_codegraph_for_repo "$project_path"
  register_singlerepo_mcp

  echo
  echo "✓ Codegraph setup xong."
}

# BASH_SOURCE[0] == $0 nghĩa là file đang được thực thi trực tiếp, không phải source.
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
  cg_main
fi
