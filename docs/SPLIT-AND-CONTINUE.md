# Tách `bmad-kit/` ra repo riêng & việc tiếp theo

Tài liệu này dành cho **bạn (maintainer)** để: (1) tách folder `bmad-kit/` ra một repo
GitHub độc lập, (2) phát hành release, (3) tiếp tục phát triển các phase sau.

---

## 1. Tách ra repo riêng

```bash
# 1. Copy folder ra ngoài repo octavia
cp -R /path/to/octavia/bmad-kit ~/bmad-kit
cd ~/bmad-kit

# 2. Init repo mới
git init -b main
git add .
git commit -m "feat: BMAD Kit 1.0.0 — packaged, generic, Claude Code format"

# 3. Tạo repo trên GitHub rồi:
git remote add origin https://github.com/vncharles/fci-bmad-kit.git
git push -u origin main
```

## 2. `REPO_URL` để curl|bash chạy được

Trong `install.sh` biến đầu file đã trỏ về repo GitHub:
```bash
REPO_URL="${BMAD_KIT_REPO_URL:-https://github.com/vncharles/fci-bmad-kit.git}"
REPO_BRANCH="${BMAD_KIT_REPO_BRANCH:-main}"
```
Raw URL của GitHub dùng host `raw.githubusercontent.com`:
```
https://raw.githubusercontent.com/vncharles/fci-bmad-kit/main/install.sh
```
→ Lệnh cài cuối cùng cho mọi team (repo Public nên chạy ngay):
```bash
curl -sSL https://raw.githubusercontent.com/vncharles/fci-bmad-kit/main/install.sh | bash
```

> ⚠️ Nếu sau này để repo **private**, `curl`/`git clone` cần auth. Lựa chọn:
> - Giữ repo Public (hiện tại), hoặc
> - Hướng dẫn team `git clone` tay rồi chạy `./install.sh /path/to/project` (local mode).

## 3. Tạo GitHub Release

Mỗi version → 1 tag + Release:
```bash
git tag -a v1.0.0 -m "BMAD Kit 1.0.0"
git push origin v1.0.0
```
Tạo Release bằng `gh` CLI (hoặc GitHub UI: **Releases → Draft a new release**, chọn tag `v1.0.0`):
```bash
gh release create v1.0.0 --title "BMAD Kit 1.0.0" --notes-file CHANGELOG.md
```
(Tùy chọn) đính kèm tarball `bmad-kit-1.0.0.tar.gz` để team pin version.

## 4. Test trước khi công bố

```bash
cd ~/bmad-kit
./install.sh /tmp/test-project        # tạo /tmp/test-project trước
ls -R /tmp/test-project/.bmad /tmp/test-project/.claude/commands
cat /tmp/test-project/team-config.md  # phải là template
./install.sh /tmp/test-project        # chạy lần 2: team-config.md không bị đè
```
Checklist (xem `docs/DESIGN.md` mục "Tiêu chí thành công"):
- [ ] 6 command `fci-*` xuất hiện trong `.claude/commands/`
- [ ] `.bmad/{agents,skills,templates,workflows}` đầy đủ
- [ ] `team-config.md` sinh từ template, chạy lại không bị đè
- [ ] `grep -ri octavia payload` → rỗng
- [ ] Mở Claude Code trong test-project, gõ `/fci-dev` → agent nhận role

## 5. Roadmap phase sau

| Phase | Việc |
|-------|------|
| 2 | Hỗ trợ **Cursor** (`.cursor/rules/`) + `.github/pull_request_template.md` trong installer |
| 3 | Hỗ trợ **Codex / provider khác** (map format tương ứng) |
| 4 | `install.sh --check`/`--update`: so `.bmad/.kit-version` với VERSION, cảnh báo out-of-date |
| 5 | (Tùy chọn) đóng gói thành **Claude Code plugin** thay vì copy file thủ công |

## 6. Quy ước bump version
- Sửa nội dung agent/skill/template → bump **minor** (`1.x.0`), update `VERSION` + `CHANGELOG.md`.
- Sửa nhỏ/typo → bump **patch** (`1.0.x`).
- Đổi cấu trúc cài đặt / breaking → bump **major**.
- Luôn tag + release khớp với `VERSION`.

---

**Nguồn gốc:** kit này được tách ra từ bộ BMAD trong repo `octavia`
(branch `fci-2025.2-1.0.0`), đã genericize bỏ mọi thứ riêng octavia.
Thiết kế đầy đủ: `docs/DESIGN.md`.
