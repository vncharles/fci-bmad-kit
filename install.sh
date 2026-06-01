#!/usr/bin/env bash
#
# BMAD Kit installer — cài bộ agent/skill BMAD (Claude Code format) vào 1 project.
#
# Dùng:
#   Remote (1 lệnh):   curl -sSL <REPO_RAW_URL>/install.sh | bash
#   Remote + target:   curl -sSL <REPO_RAW_URL>/install.sh | bash -s -- /path/to/project
#   Local (trong kit): ./install.sh [target-dir]
#
# Sau khi cài: mở Claude Code, gõ /fci-po /fci-ba /fci-dev /fci-tester để dùng ngay.

set -euo pipefail

# ─────────────────────────────────────────────────────────────────────────────
# CẤU HÌNH — điền sau khi tách folder này ra repo GitLab riêng
# ─────────────────────────────────────────────────────────────────────────────
REPO_URL="${BMAD_KIT_REPO_URL:-https://gitlab.fci.vn/iaas/lbaas/bmad-kit.git}"
REPO_BRANCH="${BMAD_KIT_REPO_BRANCH:-main}"
# ─────────────────────────────────────────────────────────────────────────────

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; BLUE='\033[0;34m'; NC='\033[0m'
info()  { printf "${BLUE}ℹ️  %s${NC}\n" "$1"; }
ok()    { printf "${GREEN}✅ %s${NC}\n" "$1"; }
warn()  { printf "${YELLOW}⚠️  %s${NC}\n" "$1"; }
err()   { printf "${RED}❌ %s${NC}\n" "$1" >&2; }

TARGET_DIR="${1:-$PWD}"

# ─────────────────────────────────────────────────────────────────────────────
# Xác định nguồn payload: local (cạnh script) hay remote (clone)
# ─────────────────────────────────────────────────────────────────────────────
SCRIPT_DIR=""
if [ -n "${BASH_SOURCE[0]:-}" ] && [ -f "${BASH_SOURCE[0]}" ]; then
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
fi

CLEANUP_TMP=""
cleanup() { [ -n "$CLEANUP_TMP" ] && rm -rf "$CLEANUP_TMP"; }
trap cleanup EXIT

if [ -n "$SCRIPT_DIR" ] && [ -d "$SCRIPT_DIR/payload" ]; then
  KIT_DIR="$SCRIPT_DIR"
  info "Chế độ LOCAL — dùng payload tại: $KIT_DIR"
else
  info "Chế độ REMOTE — clone từ: $REPO_URL ($REPO_BRANCH)"
  command -v git >/dev/null 2>&1 || { err "Cần 'git' để chạy remote install."; exit 1; }
  CLEANUP_TMP="$(mktemp -d)"
  if ! git clone --depth 1 --branch "$REPO_BRANCH" "$REPO_URL" "$CLEANUP_TMP/bmad-kit" 2>/dev/null; then
    err "git clone thất bại. Repo private? Hãy đăng nhập git trước, hoặc clone tay rồi chạy ./install.sh"
    exit 1
  fi
  KIT_DIR="$CLEANUP_TMP/bmad-kit"
  [ -d "$KIT_DIR/payload" ] || { err "Không tìm thấy payload/ trong repo."; exit 1; }
fi

VERSION="$(cat "$KIT_DIR/VERSION" 2>/dev/null | head -n1 || echo "unknown")"

# ─────────────────────────────────────────────────────────────────────────────
# Validate target
# ─────────────────────────────────────────────────────────────────────────────
[ -d "$TARGET_DIR" ] || { err "Target không tồn tại: $TARGET_DIR"; exit 1; }
TARGET_DIR="$(cd "$TARGET_DIR" && pwd)"
info "Cài BMAD Kit v$VERSION vào: $TARGET_DIR"

# ─────────────────────────────────────────────────────────────────────────────
# 1) .bmad/  (ghi đè file do kit quản lý; KHÔNG đè team-config.md)
# ─────────────────────────────────────────────────────────────────────────────
mkdir -p "$TARGET_DIR/.bmad"
for sub in agents skills templates workflows; do
  rm -rf "$TARGET_DIR/.bmad/$sub"
  cp -R "$KIT_DIR/payload/bmad/$sub" "$TARGET_DIR/.bmad/$sub"
  ok ".bmad/$sub/"
done

# team-config.md: tạo từ template nếu chưa có, không đè
if [ -f "$TARGET_DIR/team-config.md" ]; then
  warn "team-config.md đã tồn tại — giữ nguyên (không đè)."
else
  cp "$KIT_DIR/payload/bmad/team-config.template.md" "$TARGET_DIR/team-config.md"
  ok "team-config.md (tạo mới từ template — hãy điền context project)"
fi

# ─────────────────────────────────────────────────────────────────────────────
# 2) .claude/commands/  (ghi đè 6 command fci-*)
# ─────────────────────────────────────────────────────────────────────────────
mkdir -p "$TARGET_DIR/.claude/commands"
cp "$KIT_DIR"/payload/claude/commands/fci-*.md "$TARGET_DIR/.claude/commands/"
ok ".claude/commands/ (fci-po, fci-ba, fci-dev, fci-tester, fci-bmad-handoff, fci-bmad-status)"

# ─────────────────────────────────────────────────────────────────────────────
# 3) handoff/ + version marker
# ─────────────────────────────────────────────────────────────────────────────
mkdir -p "$TARGET_DIR/handoff"
printf "%s\n" "$VERSION" > "$TARGET_DIR/.bmad/.kit-version"

# ─────────────────────────────────────────────────────────────────────────────
echo ""
ok "Đã cài BMAD Kit v$VERSION."
echo ""
echo "📋 Bước tiếp theo:"
echo "   1. Mở/điền  team-config.md  với context của project"
echo "   2. Mở Claude Code và gõ:"
echo "        /fci-po       → Product Owner"
echo "        /fci-ba       → Business Analyst"
echo "        /fci-dev      → Developer"
echo "        /fci-tester   → Tester"
echo "        /fci-bmad-status   → xem trạng thái workflow"
echo "        /fci-bmad-handoff  → tạo handoff giữa các role"
echo ""
