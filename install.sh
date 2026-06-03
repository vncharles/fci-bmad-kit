#!/usr/bin/env bash
#
# FCI BMad Kit — orchestrator: chạy cả 2 bước.
#   1) install-bmad.sh        — cài BMad (bmm + tea + fci) cho claude-code
#   2) install-codegraph.sh   — setup Codegraph MCP (bỏ qua nếu SETUP_CODEGRAPH=0)
#
# Muốn chạy riêng từng phần thì gọi thẳng install-bmad.sh / install-codegraph.sh.
#
# Dùng:
#   ./install.sh                                  # chạy local
#   curl -fsSL .../install.sh | bash              # chạy qua mạng (tự tải 2 script con)
#   SETUP_CODEGRAPH=0 ./install.sh                # chỉ cài BMad
#   TARGET_DIR=/path USER_NAME="Trong" ./install.sh

set -euo pipefail

SETUP_CODEGRAPH="${SETUP_CODEGRAPH:-1}"   # 1 = setup Codegraph sau khi cài BMad, 0 = bỏ qua
RAW_BASE="${RAW_BASE:-https://raw.githubusercontent.com/vncharles/fci-bmad-kit/main}"

# Thư mục chứa script này (rỗng nếu chạy qua `curl | bash`).
HERE=""
if [ -n "${BASH_SOURCE:-}" ] && [ -f "${BASH_SOURCE[0]}" ]; then
  HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
fi

# Forward chỉ những biến đã được set sang script con (giữ nguyên default của chúng).
for v in TARGET_DIR MODULES TOOLS CUSTOM_SOURCE CHANNEL BMAD_VERSION \
         USER_NAME COMM_LANG DOC_LANG OUTPUT_FOLDER HANDOFF_FOLDER \
         AUTO_INSTALL_NODE NODE_VERSION NVM_VERSION; do
  [ -n "${!v:-}" ] && export "$v"
done

# Chạy một script con: ưu tiên file local, fallback tải từ RAW_BASE.
run_step() {
  local name="$1"
  if [ -n "$HERE" ] && [ -f "$HERE/$name" ]; then
    bash "$HERE/$name"
  else
    echo "▶ Tải $name từ $RAW_BASE"
    curl -fsSL "$RAW_BASE/$name" | bash
  fi
}

run_step install-bmad.sh

if [ "$SETUP_CODEGRAPH" = "1" ]; then
  echo
  run_step install-codegraph.sh
else
  echo
  echo "• Bỏ qua setup Codegraph (SETUP_CODEGRAPH=0)."
fi

echo
echo "✓ Hoàn tất."
