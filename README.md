# BMAD Kit

Bộ **agent + skill + workflow** theo phương pháp BMAD, đóng gói dùng chung cho mọi team —
cài vào project bằng **một lệnh**, gọi agent dùng được ngay trong **Claude Code**.

> Đây là khuôn mẫu (template) các team đều theo. Mỗi project chỉ cài kit + điền
> `team-config.md`; mọi context riêng (stack, branch, lint/test command) nằm trong file đó.

## Cài nhanh

**Remote (1 lệnh — chạy tại thư mục project):**
```bash
curl -sSL https://raw.githubusercontent.com/vncharles/fci-bmad-kit/main/install.sh | bash
```
Hoặc chỉ định project khác:
```bash
curl -sSL https://raw.githubusercontent.com/vncharles/fci-bmad-kit/main/install.sh | bash -s -- /path/to/project
```

**Local (test trước khi đẩy lên repo):**
```bash
./install.sh                 # cài vào thư mục hiện tại
./install.sh /path/to/project
```

> Repo: https://github.com/vncharles/fci-bmad-kit (Public, branch `main`).
> Có thể override bằng biến `BMAD_KIT_REPO_URL` / `BMAD_KIT_REPO_BRANCH` nếu cần.

## Sau khi cài

Kit đặt vào project:
```
<project>/
├── .bmad/                  # agents, skills, templates, workflows
│   └── .kit-version        # version đã cài
├── .claude/commands/       # fci-po, fci-ba, fci-dev, fci-tester, fci-bmad-handoff, fci-bmad-status
├── team-config.md          # ★ điền context project (KHÔNG bị đè khi update)
└── handoff/                # nơi các role trao đổi
```

Mở Claude Code và gõ:

| Command            | Role / việc                         |
|--------------------|-------------------------------------|
| `/fci-po`          | Product Owner — PRD, Epic           |
| `/fci-ba`          | Business Analyst — Story, AC        |
| `/fci-dev`         | Developer — Task, implement         |
| `/fci-tester`      | Tester — Test plan                  |
| `/fci-bmad-status` | Xem trạng thái workflow             |
| `/fci-bmad-handoff`| Tạo handoff giữa các role           |

## Cấu trúc kit

```
bmad-kit/
├── install.sh        # entry point duy nhất
├── VERSION
├── README.md
├── CHANGELOG.md
├── docs/             # design spec + hướng dẫn tách-repo & maintain
└── payload/          # nội dung được cài vào project
    ├── bmad/         # → <project>/.bmad/
    └── claude/       # → <project>/.claude/
```

## Conflict policy khi cài lại / update

- Ghi **đè** các file do kit quản lý (`.bmad/agents|skills|templates|workflows`, các `fci-*` command) để đồng bộ version mới.
- **Không bao giờ** đè `team-config.md` (context riêng của team).

## Phase sau (chưa có)
- Hỗ trợ Cursor / Codex / provider khác.
- Cơ chế version-check & auto-update.

Chi tiết thiết kế & hướng dẫn maintain: xem `docs/`.
