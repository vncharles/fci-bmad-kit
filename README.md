# FCI BMad Kit

Một **BMad Method module** định nghĩa 4 agent theo quy trình FCI:

| Slash command | Agent | Tên | Vai trò |
|---|---|---|---|
| `/fci-po` | Product Owner | Thanh | Viết PRD, tạo Epics, sign-off |
| `/fci-ba` | Business Analyst | Vanh | Viết User Stories (INVEST) |
| `/fci-dev` | Developer | Zitech | Implement + Codegraph MCP |
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

### Cách 1 — Cài nhanh (script, không hỏi-đáp)

Có 3 script ở gốc repo:

| Script | Việc |
|---|---|
| [`install.sh`](install.sh) | Orchestrator — single-repo (mặc định) hoặc multi-repo (`WORKSPACE_MODE=1`) |
| [`init-workspace.sh`](init-workspace.sh) | **Multi-repo** — clone nhiều repo vào 1 workspace + codegraph + BMad |
| [`install-bmad.sh`](install-bmad.sh) | Chỉ cài BMad (bmm + tea + fci) cho IDE claude-code |
| [`install-codegraph.sh`](install-codegraph.sh) | Chỉ setup Codegraph MCP cho project (hoặc source làm thư viện) |

**Cài tất cả (1 lệnh):**

```bash
# trong thư mục project của bạn
curl -fsSL https://raw.githubusercontent.com/vncharles/fci-bmad-kit/main/install.sh | bash
```

**Chạy riêng từng phần** (local sau khi clone, hoặc qua curl):

```bash
./install-bmad.sh          # chỉ BMad
./install-codegraph.sh     # chỉ Codegraph MCP
./install.sh               # cả hai (= bmad rồi codegraph)
```

> `install.sh` ưu tiên dùng 2 script con cạnh nó; khi chạy qua `curl | bash` (không có file local) nó tự tải 2 script con từ `RAW_BASE` (mặc định nhánh `main` của repo này).

Override mặc định qua biến môi trường (tất cả đều optional):

```bash
TARGET_DIR=/path/to/project \
USER_NAME="Trong" \
COMM_LANG="Vietnamese" \
DOC_LANG="Vietnamese" \
HANDOFF_FOLDER="handoff" \
CHANNEL="stable" \
./install.sh
```

| Biến env | Mặc định | Ý nghĩa |
|---|---|---|
| `TARGET_DIR` | `.` | Thư mục cài |
| `MODULES` | `bmm,tea,fci` | Module cần cài |
| `TOOLS` | `claude-code` | IDE/tool |
| `CUSTOM_SOURCE` | git URL repo này | Nguồn module fci |
| `CHANNEL` | `stable` | `stable` \| `next` |
| `USER_NAME` | username hệ thống | Tên agent gọi bạn |
| `COMM_LANG` / `DOC_LANG` | `Vietnamese` | Ngôn ngữ giao tiếp / tài liệu |
| `OUTPUT_FOLDER` | `_bmad-output` | Thư mục output |
| `HANDOFF_FOLDER` | `handoff` | Nơi lưu handoff giữa các role |
| `SETUP_CODEGRAPH` | `1` | `1` = tự cài & setup Codegraph MCP, `0` = bỏ qua |
| `WORKSPACE_MODE` | `0` | `1` = multi-repo workspace (ủy quyền cho `init-workspace.sh`) |
| `WORKSPACE_NAME` | tên thư mục | Tên workspace ghi vào `workspace.yml` (multi-repo) |
| `AUTO_INSTALL_NODE` | `1` | `1` = tự cài Node qua nvm nếu thiếu/cũ, `0` = chỉ báo lỗi |
| `NODE_VERSION` | `20` | Major Node sẽ cài khi auto-install |

> **Node:** bmad-method 6.8+ cần Node `>=20.12`. Script tự kiểm tra; nếu máy **chưa có Node hoặc Node quá cũ**, mặc định nó **tự cài Node qua nvm** (cài luôn nvm vào `$HOME` nếu chưa có — user-space, không cần sudo). Muốn tự quản lý Node thì đặt `AUTO_INSTALL_NODE=0`.
>
> Sau đó script chạy `npx bmad-method install` (đầy đủ flag non-interactive), rồi **setup Codegraph MCP** cho project: cài [`@optave/codegraph`](https://github.com/optave/ops-codegraph-tool) (gỡ package `codegraph` cũ nếu xung đột bin) → `codegraph build <project>` → `claude mcp add codegraph -- codegraph mcp`. Các agent đọc code (dev/ba/tester) dùng Codegraph để duyệt code nhanh; nếu không cần, đặt `SETUP_CODEGRAPH=0`.

### Cách 2 — Cài tương tác (qua BMad installer)

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
/fci-dev      → Zitech (Developer)
/fci-tester   → Hanh (QA Tester)
```

---

## Multi-repo workspace mode (team)

Dành cho **đội người thật**: PO, BA, Dev, Tester — mỗi người một máy, chỉ dùng agent của mình.
Dự án gồm nhiều repo (vd LBaaS: repo `docs` chứa PRD/epic/story của cả dịch vụ + các app repo
`octavia`, `octavia-dashboard`, ...). **Điều phối giữa các vai diễn ra QUA GIT trên repo `docs` chung** —
không cần chung máy.

```bash
# Cách 1 — KHÔNG cần clone kit: chạy thẳng từ thư mục workspace (rỗng) của bạn
WORKSPACE_MODE=1 \
  bash -c "$(curl -fsSL https://raw.githubusercontent.com/vncharles/fci-bmad-kit/main/install.sh)"

# Cách 2 — đã clone kit về:
WORKSPACE_MODE=1 TARGET_DIR=/path/to/workspace ./install.sh
# hoặc gọi thẳng:
./init-workspace.sh
```

Script sẽ **hỏi vai trò ngay khi chạy** (menu 1=PO · 2=BA · 3=Dev · 4=Tester) — không cần khai báo trước.
Muốn bỏ qua bước hỏi thì đặt sẵn `ROLE=dev` (po|ba|dev|tester) trước lệnh.

> One-liner vẫn **tương tác bình thường** (prompt đọc từ `/dev/tty`); nó tự tải `init-workspace.sh`
> + `install-codegraph.sh` + `install-bmad.sh` về thư mục tạm rồi chạy. Workspace mặc định là thư mục
> hiện tại — `cd` vào thư mục workspace trống trước khi chạy, hoặc đặt `TARGET_DIR`.

`init-workspace.sh` (tương tác — **phải chạy local**, không hỗ trợ `curl | bash`):

1. Hỏi **role**. Clone repo **`docs`** (bắt buộc, tên cố định, **không** codegraph).
2. Tạo/đọc **`docs/workspace.yml`** — registry repo của dự án, **nằm trong repo docs** để share qua git.
3. **App repo**: với mỗi repo đã khai báo trong registry → hỏi clone về; và cho **khai báo repo mới**
   (tên + URL + branch). Khi clone code: `codegraph build <repo>` (tự đăng ký vào registry chung của codegraph).
4. Nếu có ≥1 app repo build: đăng ký **một** MCP `claude mcp add codegraph -- codegraph mcp --multi-repo`.
5. Cài BMad ở **workspace root**, trỏ artifacts + handoff vào repo `docs`.
6. Hỏi commit & push `docs/workspace.yml` lên GitLab cho cả đội (bán tự động).

**Clone theo role** (PO không cần đọc code; BA cần hiểu ràng buộc kỹ thuật nên cũng clone code):

| Role | Clone | Codegraph |
|---|---|---|
| PO | chỉ `docs` | không |
| BA / Dev / Tester | `docs` + app repo | có |

> Codegraph = [`@optave/codegraph`](https://github.com/optave/ops-codegraph-tool) (multi-repo native):
> một MCP server phục vụ mọi repo đã build, mỗi tool có param `repo` + tool `list_repos`.
> Yêu cầu: máy đã **login GitLab sẵn**. Script chỉ `git clone`/`git pull`.

> **Dùng cho dự án/team khác:** copy [`workspace.template.yml`](workspace.template.yml) vào repo docs,
> đổi tên thành `workspace.yml`, sửa URL/branch các repo, rồi push. Người sau chỉ dán URL repo docs một
> lần — script đọc manifest và tự clone phần còn lại (không phải nhập lại từng link).

Layout kết quả (mọi thứ share đều nằm **trong repo `docs`**):

```
<workspace>/
├── _bmad/                 # BMad + module fci (cài 1 lần ở workspace root)
├── docs/                  # REPO docs — HUB CHIA SẺ (share qua git)
│   ├── workspace.yml      #   registry repo của dự án
│   ├── handoff/           #   handoff giữa các role
│   └── prd/ epics/ stories/ tasks/ test-plans/
├── octavia/               # app repo + docs/project-context.md + .codegraph/  (registry: octavia)
└── octavia-dashboard/     # app repo + docs/project-context.md + .codegraph/  (registry: octavia-dashboard)
```

**Điều phối đội qua git — KHÔNG cần biết git (PO/BA yên tâm):** agent làm git thay bạn, chỉ hỏi có/không:

- **Lúc activate**: agent hỏi *"Pull việc mới nhất của đồng đội từ repo docs?"* → bạn trả lời **có/không**;
  nếu có, agent tự chạy `git pull` (bạn không gõ lệnh). Rồi đọc `docs/workspace.yml`, **hỏi bạn chọn app repo**.
- **Sau khi xong**: agent hỏi *"Đẩy kết quả lên repo docs cho đội?"* → **có/không**; nếu có, agent tự
  `add + commit + push`. Nếu bị từ chối, agent tự `pull --rebase` rồi push lại; conflict thật mới dừng và
  nhờ người biết git (Dev). Máy đã login GitLab sẵn nên không phải nhập gì.

Còn lại:

- Dev/Tester gọi **codegraph MCP chung** với param `repo=<repo>` và đọc
  `<repo>/docs/project-context.md` để hiểu tech stack.
- PO/BA ghi PRD/epic/story vào **repo `docs`** (`docs/prd`, `docs/epics`, `docs/stories`) theo
  struct + template BMad, ghi rõ *affected repo(s)*. Code thì Dev push riêng ở app repo qua branch/MR.
- `fci-dev` có menu **BC** bootstrap `<repo>/docs/project-context.md` bằng `bmad-document-project` + codegraph.

> **Giới hạn cần biết:** git không có notification (cần ping Slack/GitLab khi handoff); codegraph index
> **từng repo riêng**, không nối lời gọi chéo repo (ranh giới API mô tả trong `docs/`); sau khi code đổi
> nhiều cần `codegraph build <repo>` lại để graph chính xác.

---

## Workflow

```
PO (Thanh)  →  BA (Vanh)  →  Dev (Zitech)  →  Tester (Hanh)  →  PO sign-off
```

Handoff files (file-based, trong repo docs tại `docs/handoff/` — share qua git giữa các thành viên):

- `docs/handoff/po-to-ba-[feature].md`
- `docs/handoff/ba-to-dev-[feature].md`
- `docs/handoff/dev-to-tester-[story-id].md`
- `docs/handoff/tester-to-po-[story-id]-approved.md`
- `docs/handoff/tester-to-dev-BUG-[id].md`

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
