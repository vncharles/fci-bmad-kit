# BMAD Kit — Changelog

## [2.0.0] — 2026-06-03

### Changed (BREAKING) — đóng gói lại thành BMad module cài được qua installer
- Tái cấu trúc repo thành **BMad external module package** (`package.json` + `src/module.yaml` + `src/agents/`).
  Giờ cài bằng cách dán git URL vào `npx bmad-method install` → chọn Custom module, thay vì copy file thủ công.
- 4 agent chuyển từ **sparse override** trên agent của `bmm`/`tea` (`bmad-agent-pm`, `bmad-tea`, …)
  thành **agent FCI độc lập**: `fci-po` (Thanh), `fci-ba` (Vanh), `fci-dev` (Hieu), `fci-tester` (Hanh).
  Mỗi agent có persona riêng + menu trỏ tới skill của `bmm`/`tea`.
- Slash command `/fci-*` giờ do installer sinh ra từ module, không còn là file rời trong `.claude/commands/`
  (vốn bị `.gitignore` bỏ qua → không lên git → là một lý do bản cũ "không chạy được").

### Prerequisites
- Yêu cầu cài kèm `bmm` (built-in) và `tea` (external) để các menu skill resolve được.

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
