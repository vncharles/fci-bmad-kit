#!/usr/bin/env bash
#
# FCI BMad Kit — orchestrator.
#
# SINGLE-REPO mode (mặc định): cài BMad + Codegraph vào một repo.
#   1) install-bmad.sh        — cài BMad (bmm + tea + fci) cho claude-code
#   2) install-codegraph.sh   — setup Codegraph MCP (bỏ qua nếu SETUP_CODEGRAPH=0)
#
# MULTI-REPO mode (WORKSPACE_MODE=1): khởi tạo workspace nhiều repo qua init-workspace.sh.
#
# Muốn chạy riêng từng phần thì gọi thẳng init-workspace.sh / install-bmad.sh / install-codegraph.sh.
#
# Dùng:
#   ./install.sh                                  # single-repo, chạy local
#   WORKSPACE_MODE=1 ./install.sh                 # multi-repo workspace (tương tác)
#   curl -fsSL .../install.sh | bash              # chạy qua mạng (tự tải script con)
#   SETUP_CODEGRAPH=0 ./install.sh                # chỉ cài BMad
#   TARGET_DIR=/path USER_NAME="Trong" ./install.sh

set -euo pipefail

WORKSPACE_MODE="${WORKSPACE_MODE:-0}"     # 1 = multi-repo workspace, 0 = single-repo
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
         WORKSPACE_NAME SETUP_BMAD \
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

# ── MULTI-REPO mode: ủy quyền hoàn toàn cho init-workspace.sh ─────────────────────
if [ "$WORKSPACE_MODE" = "1" ]; then
  if [ -n "$HERE" ] && [ -f "$HERE/init-workspace.sh" ]; then
    # Chạy local (đã clone kit).
    bash "$HERE/init-workspace.sh"
  else
    # curl | bash: tải các script cần thiết về thư mục tạm rồi chạy.
    # (init-workspace.sh source install-codegraph.sh và gọi install-bmad.sh nên cần cả 3.)
    # Prompt đọc từ /dev/tty nên vẫn tương tác bình thường qua pipe.
    TMP="$(mktemp -d)"
    trap 'rm -rf "$TMP"' EXIT
    echo "▶ Tải scripts về $TMP từ $RAW_BASE"
    for s in init-workspace.sh install-codegraph.sh install-bmad.sh; do
      curl -fsSL "$RAW_BASE/$s" -o "$TMP/$s" || { echo "✗ Tải $s thất bại." >&2; exit 1; }
    done
    chmod +x "$TMP"/*.sh
    bash "$TMP/init-workspace.sh"
  fi
  echo
  echo "✓ Hoàn tất (workspace mode)."
  exit 0
fi

# ── SINGLE-REPO mode (mặc định) ──────────────────────────────────────────────────
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
