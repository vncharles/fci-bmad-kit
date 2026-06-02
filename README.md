# FCI BMad Kit

Bộ **customization** cho [BMad Method](https://github.com/bmad-method/bmad) — định nghĩa 4 agent theo quy trình FCI: **PO → BA → Dev → Tester**.

Cài trực tiếp qua BMad Method, không cần script riêng.

---

## Yêu cầu

- [BMad Method](https://github.com/bmad-method/bmad) đã được cài vào project (`_bmad/` tồn tại).

---

## Cài đặt

### Bước 1 — Cài BMad Method (nếu chưa có)

Làm theo hướng dẫn chính thức tại repo BMad Method.

### Bước 2 — Apply FCI customizations

Copy 2 thứ từ repo này vào project:

**TOML overrides** (vào `_bmad/custom/`):
```bash
cp _bmad/custom/config.toml          <project>/_bmad/custom/config.toml
cp _bmad/custom/bmad-agent-analyst.toml  <project>/_bmad/custom/
cp _bmad/custom/bmad-agent-pm.toml       <project>/_bmad/custom/
cp _bmad/custom/bmad-agent-dev.toml      <project>/_bmad/custom/
cp _bmad/custom/bmad-tea.toml            <project>/_bmad/custom/
```

**Slash commands** (vào `.claude/commands/`):
```bash
cp .claude/commands/fci-*.md  <project>/.claude/commands/
```

### Bước 3 — Dùng ngay trong Claude Code

| Command | Agent | Tên |
|---|---|---|
| `/fci-po` | Product Owner | Thanh |
| `/fci-ba` | Business Analyst | Vanh |
| `/fci-dev` | Developer | Hieu |
| `/fci-tester` | QA Tester | Hanh |

---

## Cấu trúc repo

```
fci-bmad-kit/
├── _bmad/
│   └── custom/
│       ├── config.toml              # agent names
│       ├── bmad-agent-analyst.toml  # BA (Vanh)
│       ├── bmad-agent-pm.toml       # PO (Thanh)
│       ├── bmad-agent-dev.toml      # Dev (Hieu)
│       └── bmad-tea.toml            # Tester (Hanh)
├── .claude/
│   └── commands/
│       ├── fci-ba.md
│       ├── fci-po.md
│       ├── fci-dev.md
│       └── fci-tester.md
├── VERSION
├── CHANGELOG.md
└── README.md
```

---

## Workflow

```
PO (Thanh)  →  BA (Vanh)  →  Dev (Hieu)  →  Tester (Hanh)  →  PO sign-off
```

Handoff files:
- `handoff/po-to-ba-[feature].md`
- `handoff/ba-to-dev-[feature].md`
- `handoff/dev-to-tester-[story-id].md`
- `handoff/tester-to-po-[story-id]-approved.md`
- `handoff/tester-to-dev-BUG-[id].md`

---

## Update customizations

Các TOML files trong `_bmad/custom/` là **sparse overrides** — chỉ chứa những gì khác với BMad default. Khi BMad Method update, chạy lại BMad installer; overrides của FCI không bị đè.
