#!/usr/bin/env bash
#
# FCI BMad Kit — one-shot non-interactive installer.
#
# Bỏ qua phần hỏi-đáp của `npx bmad-method install`. Cài sẵn:
#   - bmm  (built-in BMad: bmad-prd, bmad-create-story, bmad-dev-story, ...)
#   - tea  (external: bmad-method-test-architecture-enterprise)
#   - fci  (module này, lấy từ git URL bên dưới)
# rồi cấu hình cho IDE claude-code.
#
# Dùng:
#   ./install.sh                         # cài vào thư mục hiện tại với mặc định
#   TARGET_DIR=/path/to/project ./install.sh
#   USER_NAME="Trong" COMM_LANG="Vietnamese" ./install.sh
#
# Mọi giá trị dưới đây đều override được bằng biến môi trường.

set -euo pipefail

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

echo "▶ Cài FCI BMad Kit (non-interactive)"
echo "  dir=$TARGET_DIR  modules=$MODULES  tools=$TOOLS  channel=$CHANNEL"
echo "  user=$USER_NAME  comm=$COMM_LANG  doc=$DOC_LANG  handoff=$HANDOFF_FOLDER"
echo

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
  --set "fci.fci_handoff_folder=$HANDOFF_FOLDER"

echo
echo "✓ Xong. Dùng trong Claude Code: /fci-po  /fci-ba  /fci-dev  /fci-tester"
