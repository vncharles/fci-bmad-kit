#!/usr/bin/env bash
#
# FCI BMad Kit — setup Codegraph MCP cho project. Standalone, chạy độc lập được.
#
# Các agent đọc code (dev/ba/tester) dùng Codegraph để duyệt code nhanh, tiết kiệm token.
# Script: kiểm tra codegraph → cài nếu thiếu → init + status → add MCP vào Claude Code.
#
# Dùng:
#   ./install-codegraph.sh
#   TARGET_DIR=/path/to/project ./install-codegraph.sh
#
# Mọi giá trị dưới đây đều override được bằng biến môi trường.

set -euo pipefail

# ── Preflight: cần Node (để `npm install -g codegraph`) ─────────────────────────
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
  if node_ok; then return 0; fi
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
  bootstrap_node_via_nvm
  node_ok || { echo "✗ Vẫn chưa có Node hợp lệ. Mở terminal mới, 'nvm use $NODE_VERSION' rồi thử lại." >&2; exit 1; }
}

# ── Lựa chọn ───────────────────────────────────────────────────────────────────
TARGET_DIR="${TARGET_DIR:-.}"                 # project để setup codegraph
PROJECT_PATH="$(cd "$TARGET_DIR" && pwd)"     # đường dẫn tuyệt đối

require_node

echo "▶ Setup Codegraph MCP cho: $PROJECT_PATH"

# 1) Kiểm tra codegraph, cài nếu thiếu
if codegraph --version >/dev/null 2>&1; then
  echo "  ✓ codegraph đã có: $(codegraph --version 2>&1 | head -n1)"
else
  echo "  • Chưa có codegraph — đang cài: npm install -g codegraph"
  npm install -g codegraph
fi

# 2) Init + status trong thư mục project
(
  cd "$PROJECT_PATH"
  echo "  • codegraph init"
  codegraph init || echo "    ⚠ codegraph init lỗi/đã init trước đó — bỏ qua."
  echo "  • codegraph status"
  codegraph status || true
)

# 3) Đăng ký MCP server vào Claude Code
if command -v claude >/dev/null 2>&1; then
  echo "  • claude mcp add codegraph"
  claude mcp add codegraph -- codegraph serve --mcp --path "$PROJECT_PATH" \
    || echo "    ⚠ Không add được (có thể đã tồn tại). Bỏ qua."
else
  echo "  ⚠ Không tìm thấy CLI 'claude' — bỏ qua bước add MCP."
  echo "    Chạy thủ công sau: claude mcp add codegraph -- codegraph serve --mcp --path \"$PROJECT_PATH\""
fi

echo
echo "✓ Codegraph setup xong."
