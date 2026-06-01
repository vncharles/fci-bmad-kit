# BMAD Kit — Changelog

## [1.0.0] — 2026-06-01

### Added
- Đóng gói BMAD thành kit độc lập, generic, install bằng 1 script (`install.sh`).
- Hỗ trợ **Claude Code format**: slash commands `.claude/commands/fci-*` + `.bmad/`.
- Agents: PO, BA, Dev, Tester.
- Skills: create-prd, create-epic, create-story, create-task, create-test-plan.
- Templates: PRD, Epic, Story, Task, Test Plan.
- Workflows: feature-workflow, bug-workflow.
- `team-config.template.md` — mỗi team tự điền context riêng (không bị đè khi update).
- Commands đổi tên thêm prefix `fci-` (`/fci-po`, `/fci-ba`, `/fci-dev`, `/fci-tester`,
  `/fci-bmad-handoff`, `/fci-bmad-status`).
- `install.sh` 2 chế độ: remote (`curl | bash`) và local (`./install.sh [target]`).
  Conflict policy: ghi đè file do kit quản lý, giữ nguyên `team-config.md`.

### Removed (so với bản nằm trong repo octavia)
- Toàn bộ tham chiếu riêng `octavia` (genericize → trỏ về `team-config.md`).
- Cursor rules / `.github/` (sẽ hỗ trợ ở phase sau).
- Logic submodule `octavia-docs`, codegraph CLI (dùng codegraph MCP per-project).
