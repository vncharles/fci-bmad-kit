# FCI BMad Kit

Một **BMad Method module** định nghĩa 4 agent theo quy trình FCI:

| Slash command | Agent | Tên | Vai trò |
|---|---|---|---|
| `/fci-po` | Product Owner | Thanh | Viết PRD, tạo Epics, sign-off |
| `/fci-ba` | Business Analyst | Vanh | Viết User Stories (INVEST) |
| `/fci-dev` | Developer | Hieu | Implement + Codegraph MCP |
| `/fci-tester` | QA Tester | Hanh | Test plan, execute, bug report |

Cài trực tiếp qua BMad installer bằng cách **dán link git này** — không cần copy file thủ công.

---

## Yêu cầu (prerequisites)

Các agent FCI **dispatch sang skill của 2 module BMad khác**, nên phải cài kèm trong cùng lần install:

- **`bmm`** (built-in của BMad) — cung cấp: `bmad-prd`, `bmad-create-story`, `bmad-create-epics-and-stories`, `bmad-dev-story`, `bmad-quick-dev`, `bmad-code-review`, `bmad-investigate`.
- **`tea`** (external: `bmad-method-test-architecture-enterprise`) — cung cấp: `bmad-testarch-automate`, `bmad-testarch-test-review`, `bmad-testarch-trace`.

> Nếu thiếu `bmm`/`tea`, agent FCI vẫn chạy nhưng các menu trỏ tới skill của 2 module đó sẽ không resolve được.

---

## Cài đặt

Trong thư mục project của bạn:

```bash
npx bmad-method install
```

Khi installer hỏi chọn module:

1. Chọn **bmm** (Core / BMad Method).
2. Chọn **tea** (Test Architect).
3. Chọn **Custom module** (hoặc "Add a module from a git URL"), rồi dán:

   ```
   https://github.com/vncharles/fci-bmad-kit
   ```

Installer sẽ đọc [`src/module.yaml`](src/module.yaml), compile 4 agent vào `_bmad/fci/`, và đăng ký 4 skill `/fci-po`, `/fci-ba`, `/fci-dev`, `/fci-tester`.

### Dùng ngay trong Claude Code

```
/fci-po       → Thanh (Product Owner)
/fci-ba       → Vanh (Business Analyst)
/fci-dev      → Hieu (Developer)
/fci-tester   → Hanh (QA Tester)
```

---

## Workflow

```
PO (Thanh)  →  BA (Vanh)  →  Dev (Hieu)  →  Tester (Hanh)  →  PO sign-off
```

Handoff files (file-based, mặc định trong `handoff/`):

- `handoff/po-to-ba-[feature].md`
- `handoff/ba-to-dev-[feature].md`
- `handoff/dev-to-tester-[story-id].md`
- `handoff/tester-to-po-[story-id]-approved.md`
- `handoff/tester-to-dev-BUG-[id].md`

---

## Cấu trúc module (cho người maintain)

Đây là một **BMad custom module** cài qua git URL. Installer đọc `.claude-plugin/marketplace.json`
để vào *discovery mode*, rồi resolver tìm `module.yaml` + `module-help.csv` ở **thư mục cha chung của
các skill** (ở đây là `src/`):

```
fci-bmad-kit/
├── .claude-plugin/
│   └── marketplace.json         # BẮT BUỘC — liệt kê plugin "fci" + 4 skill (./src/fci-*)
├── package.json                 # package manifest (name: fci-bmad-kit)
├── src/
│   ├── module.yaml              # module manifest: code "fci" + 4 agent + install vars
│   ├── module-help.csv          # bmad-help registry
│   ├── fci-po/{SKILL.md, customize.toml}
│   ├── fci-ba/{SKILL.md, customize.toml}
│   ├── fci-dev/{SKILL.md, customize.toml}
│   └── fci-tester/{SKILL.md, customize.toml}
├── VERSION
├── CHANGELOG.md
└── README.md
```

> **Quan trọng:** thiếu `.claude-plugin/marketplace.json` thì installer chạy *direct mode* — chỉ
> quét `SKILL.md` ở thư mục con cấp 1 của gốc repo, không thấy gì → báo *"0 installable modules"*.
> Và `module.yaml`/`module-help.csv` PHẢI nằm cùng cấp cha chung của các skill liệt kê trong marketplace.

- `SKILL.md` — persona cố định + activation steps của agent.
- `customize.toml` — role, identity, principles, persistent_facts và **menu** (mỗi item trỏ tới `skill` hoặc `prompt`).

### Tuỳ biến sau khi cài (per-project, không sửa source)

Mỗi project cài module có thể override mà không đụng tới source:

```
{project-root}/_bmad/custom/fci-po.toml        # team, committed
{project-root}/_bmad/custom/fci-po.user.toml   # personal, gitignored
```

Overrides deep-merge theo quy tắc BMad: scalar ghi đè, mảng append, array-of-tables merge theo `code`.
