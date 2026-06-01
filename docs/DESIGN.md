# BMAD Kit — Packaging Design

**Date:** 2026-06-01
**Status:** Approved (design) — pending spec review
**Author:** Trần Quốc Trọng + Claude

## Mục tiêu

Đóng gói bộ BMAD (agents + skills + templates + workflows + slash commands) hiện đang
nằm lẫn trong repo `octavia` thành **một folder self-contained, generic, dùng chung cho
mọi team**. Mỗi project chỉ cần chạy **một lệnh** để cài và gọi agent dùng được ngay
trong Claude Code.

Folder này sẽ được **tách ra một repo GitLab riêng** (do user tự làm) và phát hành theo
GitLab Release / tag. Phase này chỉ tạo folder + installer; việc push lên repo riêng nằm
ngoài phạm vi.

## Phạm vi

**Trong phạm vi (phase này):**
- Gom toàn bộ BMAD content vào 1 folder `bmad-kit/`.
- Genericize: bỏ mọi tham chiếu riêng `octavia`.
- Chỉ hỗ trợ **Claude Code format** (slash commands `.claude/commands/` + `.bmad/`).
- `install.sh`: một entry point, chạy `curl | bash` được, đồng thời chạy local được.
- Đổi tên command thêm prefix `fci-`.

**Ngoài phạm vi (xử lý sau):**
- `.cursor/rules/`, `.github/pull_request_template.md` (provider khác).
- `CLAUDE.md` / codegraph — per-project, dùng codegraph MCP, không đóng gói.
- Logic submodule `octavia-docs`.
- Việc tạo repo GitLab riêng và push release (user tự làm).

## Cấu trúc folder deliverable

Tạo tại root repo octavia: `bmad-kit/`

```
bmad-kit/
├── install.sh                  # entry point duy nhất (remote + local mode)
├── VERSION                     # 1.0.0
├── README.md                   # giới thiệu, cách install, cách gọi agent
├── CHANGELOG.md                # chuyển từ .bmad/CHANGELOG.md, đã clean
└── payload/
    ├── bmad/                   # → cài vào <target>/.bmad/
    │   ├── agents/             #   po-agent, ba-agent, dev-agent, tester-agent
    │   ├── skills/             #   create-prd/epic/story/task/test-plan
    │   ├── templates/          #   prd, epic, story, task, test-plan
    │   ├── workflows/          #   feature-workflow, bug-workflow
    │   └── team-config.template.md   # MỚI — agents tham chiếu team-config.md
    └── claude/
        └── commands/           # → cài vào <target>/.claude/commands/
            ├── fci-po.md
            ├── fci-ba.md
            ├── fci-dev.md
            ├── fci-tester.md
            ├── fci-bmad-handoff.md
            └── fci-bmad-status.md
```

## install.sh — hành vi

Một script, hai chế độ:

### Chế độ Remote (mục tiêu chính)
```bash
curl -sSL <REPO_RAW_URL>/install.sh | bash
```
- Script phát hiện không có `payload/` cạnh nó (đang chạy qua pipe) →
  `git clone --depth 1 <REPO_URL>` vào thư mục temp → copy payload → xoá temp.
- `REPO_URL` / `REPO_RAW_URL` là biến ở đầu script; để **placeholder** cho user điền
  sau khi tạo repo riêng.

### Chế độ Local (để test trước khi đẩy lên)
```bash
./install.sh [target-dir]
```
- Chạy ngay trong `bmad-kit/`, copy từ `payload/` cạnh nó.

### Target
- `target-dir` mặc định = thư mục hiện tại (`$PWD`) = project đang đứng.

### Các bước cài
1. Copy `payload/bmad/*` → `<target>/.bmad/`.
   - **Conflict policy: luôn ghi đè** các file do kit quản lý
     (agents, skills, templates, workflows) để đồng bộ version mới.
2. Copy `payload/claude/commands/*` → `<target>/.claude/commands/`.
   - **Luôn ghi đè.**
3. `team-config.md`:
   - Nếu `<target>/team-config.md` **chưa có** → tạo từ `team-config.template.md`.
   - Nếu **đã có** → **không đè** (giữ context riêng của team).
4. Ghi `<target>/.bmad/.kit-version` = nội dung `VERSION`.
5. In summary + hướng dẫn:
   > ✅ Đã cài BMAD Kit v<version>.
   > Mở Claude Code và gõ `/fci-po`, `/fci-ba`, `/fci-dev`, `/fci-tester` để dùng ngay.

### Yêu cầu kỹ thuật install.sh
- `set -euo pipefail`.
- Idempotent: chạy nhiều lần ra kết quả như nhau (trừ team-config.md được giữ).
- Không phụ thuộc tool ngoài `git`, `bash`, `cp`, `mkdir` chuẩn.
- Báo lỗi rõ nếu `git clone` thất bại (repo private cần auth → hướng dẫn user).

## Genericize

Bỏ tham chiếu `octavia` trong các file sau (thay bằng wording chung, ví dụ "project này"
hoặc đưa context vào team-config.md):
- `payload/bmad/agents/dev-agent.md`
- `payload/bmad/workflows/feature-workflow.md`
- `payload/bmad/templates/task-template.md`
- `payload/bmad/skills/create-task.md`
- `payload/claude/commands/fci-dev.md`

`team-config.template.md` là nơi mỗi team điền: tên project, repo, ghi chú codegraph MCP,
conventions riêng. Agents đọc `team-config.md` (file team tự tạo từ template) để lấy
context riêng.

## Đổi tên command (prefix fci-)

| Cũ (`.claude/commands/`) | Mới (`payload/claude/commands/`) | Slash command |
|--------------------------|----------------------------------|---------------|
| `po.md`                  | `fci-po.md`                      | `/fci-po`     |
| `ba.md`                  | `fci-ba.md`                      | `/fci-ba`     |
| `dev.md`                 | `fci-dev.md`                     | `/fci-dev`    |
| `tester.md`              | `fci-tester.md`                  | `/fci-tester` |
| `bmad-handoff.md`        | `fci-bmad-handoff.md`            | `/fci-bmad-handoff` |
| `bmad-status.md`         | `fci-bmad-status.md`             | `/fci-bmad-status`  |

Nội dung bên trong command vẫn trỏ `.bmad/agents/*.md` như cũ (không đổi).

## Tiêu chí thành công

1. Chạy `./bmad-kit/install.sh /tmp/test-project` tạo đúng `.bmad/` + `.claude/commands/`
   với 6 command prefix `fci-`, và `team-config.md` sinh từ template.
2. Chạy lần 2 không phá `team-config.md` đã chỉnh.
3. `grep -ri octavia bmad-kit/payload` không còn kết quả (trừ ví dụ trung tính nếu có).
4. Sau khi cài vào một project, mở Claude Code gõ `/fci-dev` → agent Dev nhận role ngay.
5. Folder `bmad-kit/` self-contained: zip/copy đi nơi khác vẫn cài được ở local mode.

## Mở / Quyết định sau

- URL repo GitLab riêng (user điền vào `REPO_URL` sau khi tạo).
- Hỗ trợ Cursor/Codex (phase sau).
- Cơ chế version-check / auto-update (hiện chỉ ghi `.kit-version`).
