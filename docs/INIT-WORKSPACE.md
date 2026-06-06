# `init-workspace.sh` — Giải thích thành phần & ví dụ

Tài liệu này mổ xẻ script `init-workspace.sh`: mỗi thành phần làm gì, vì sao cần,
và ví dụ cụ thể cho từng vai trò. Đọc kèm `install-codegraph.sh` và `install-bmad.sh`.

---

## 1. Mục đích tổng thể

`init-workspace.sh` khởi tạo (hoặc tham gia) một **multi-repo workspace** cho đội FCI BMad.
Đội là **người thật** — PO, BA, Dev, Tester — mỗi người một máy, mỗi người chỉ dùng agent của vai mình.
Việc điều phối giữa các vai **diễn ra qua Git** trên một repo "docs" chung.

Một lần chạy script sẽ lo trọn:

1. Clone repo **docs** (hub chia sẻ) — bắt buộc.
2. Cài **Codegraph** (`@optave/codegraph`) + engine embed (nếu vai cần đọc code).
3. Clone các **app repo** (code), **build graph + embed** từng repo, gom vào một registry chung.
4. Đăng ký **một MCP `codegraph` multi-repo** phục vụ toàn workspace.
5. Cài **BMad** ở workspace root, trỏ artifacts/handoff về repo docs.
6. Commit & push `workspace.yml` lên repo docs cho cả đội.

---

## 2. Mô hình kiến trúc

```
workspace-root/
├── docs/                      ← repo "docs" (hub chia sẻ qua Git)
│   ├── workspace.yml          ← registry: danh sách repo chuẩn của dự án
│   ├── handoff/               ← bàn giao giữa các vai (BA→Dev→Tester)
│   └── prd/ epics/ stories/ … ← artifacts BMad
├── octavia/                   ← app repo (code) — có .codegraph/
├── octavia-dashboard/         ← app repo (code) — có .codegraph/
└── octaviaclient/             ← app repo (code) — có .codegraph/

        ┌─────────── 1 MCP "codegraph --multi-repo" ───────────┐
        │  phục vụ MỌI app repo; agent truyền param repo=<name> │
        └───────────────────────────────────────────────────────┘
```

- **docs repo**: nguồn sự thật chung, KHÔNG build codegraph.
- **app repo**: code thật; mỗi repo có `.codegraph/graph.db` riêng, nhưng tất cả
  cùng đăng ký vào **một registry** (`~/.codegraph/registry.json`) và dùng **chung một MCP server**.

---

## 3. Khái niệm cốt lõi

| Khái niệm | Là gì | Mục đích |
|---|---|---|
| **Role** | `po` / `ba` / `dev` / `tester` | Quyết định có clone code + cài codegraph không |
| **docs hub** | repo tên cố định `docs` | Chia sẻ registry + handoff + artifacts qua Git |
| **workspace.yml** | file trong `docs/` | "Danh bạ" repo chuẩn của dự án, share cho cả đội |
| **app repo** | repo code (octavia, …) | Nơi codegraph build + embed |
| **registry chung** | `~/.codegraph/registry.json` | Cho phép 1 MCP phục vụ nhiều repo |
| **multi-repo MCP** | `codegraph mcp --multi-repo` | 1 server, agent chọn repo bằng param `repo` |

---

## 4. Các thành phần (hàm) trong script

### 4.1 Nhập liệu tương tác
| Hàm | Mục đích | Ví dụ |
|---|---|---|
| `ask "prompt" "default"` | Hỏi một dòng, có giá trị mặc định | `ask "Branch repo docs" "main"` → gõ Enter lấy `main` |
| `ask_yn "prompt" "y"` | Hỏi yes/no | `ask_yn "Clone repo 'octavia'?" "y"` |

> Script mở TTY trên fd 3 nên vẫn hỏi được khi chạy qua `curl … | bash`.

### 4.2 Quản lý registry (`workspace.yml`)
| Hàm | Mục đích |
|---|---|
| `reg_init_if_missing` | Tạo `workspace.yml` lần đầu (ghi entry `docs`) |
| `reg_list_app_repos` | Liệt kê repo `type: app` (TSV: name/url/branch/codegraph) |
| `reg_has_repo <name>` | Kiểm tra repo đã khai báo chưa |
| `reg_set_docs_origin <url> <branch>` | Điền url/branch thật cho entry `docs` |
| `reg_add_app_repo <name> <url> <branch>` | Thêm một app repo mới vào registry |

Ví dụ `workspace.yml` sau khi BA khai báo 2 repo:

```yaml
workspace:
  name: LBaaS
  created: 2026-06-06
  docs_repo: docs
  handoff_folder: docs/handoff
  codegraph_mcp: codegraph
  codegraph_mode: multi-repo
repos:
  - name: docs
    url: git@gitlab.com:fci/lbaas-docs.git
    branch: main
    type: docs
    codegraph: false
  - name: octavia
    url: git@gitlab.com:fci/octavia.git
    branch: main
    type: app
    codegraph: true
    registry_name: octavia
  - name: octavia-dashboard
    url: git@gitlab.com:fci/octavia-dashboard.git
    branch: main
    type: app
    codegraph: true
    registry_name: octavia-dashboard
```

### 4.3 Thao tác Git
| Hàm | Mục đích | Ghi chú |
|---|---|---|
| `git_clone_or_pull <url> <branch> <dest>` | Clone repo, hoặc `pull --ff-only` nếu đã có | Trả non-zero nếu lỗi → caller bỏ qua mềm |
| `current_branch <name>` | Lấy branch hiện tại của repo | Dùng để in báo cáo |

### 4.4 Codegraph (đến từ `install-codegraph.sh` — được `source`)
| Hàm | Mục đích | Ví dụ thực tế |
|---|---|---|
| `cg_require_node` | Đảm bảo có **Node ≥ 22** (tự cài qua nvm nếu thiếu) | Node 22 bắt buộc vì `better-sqlite3` của codegraph là prebuilt cho 22 |
| `cg_install_cli` | `npm install -g @optave/codegraph` | Cài CLI `codegraph` |
| `cg_install_engine` | `npm install -g @huggingface/transformers` (**global**) | Engine cho embed; cài global để codegraph **không** đẻ `node_modules` rác vào repo |
| `setup_codegraph_for_repo <path> <name>` | `build` + `registry add` + **`embed`** một repo | Gọi cho mỗi app repo |
| `cg_embed_repo <path>` | `codegraph embed --db <abs> --model jina-code` | Nhúng semantic cho function/method/class |
| `register_multirepo_mcp` | `claude mcp add codegraph -- <abs>/codegraph mcp --multi-repo` | Dùng **đường dẫn tuyệt đối** node 22 để MCP không gãy khi đổi default node |

---

## 5. Luồng chạy từng bước (kèm ví dụ)

Giả sử **Dev tên Trọng** tham gia workspace `LBaaS` (BA đã tạo `docs` + khai báo repo từ trước).

```bash
TARGET_DIR=~/work/LBaaS ROLE=dev ./init-workspace.sh
```

### [0] Chọn role
```
Bạn là vai trò nào?
  1) PO   2) BA   3) Dev   4) Tester
Chọn (1-4): 3
→ Role: dev  → clone docs + app repo + codegraph
```
- `po` → `CLONE_CODE=0` (chỉ docs, không đọc code).
- `ba/dev/tester` → `CLONE_CODE=1` (docs + code + codegraph).

### [1] Repo docs (bắt buộc)
```
GitLab URL cho repo docs: git@gitlab.com:fci/lbaas-docs.git
Branch repo docs [main]: ⏎
  • git clone … → docs (branch: main)
  ✓ docs sẵn sàng. Registry: ~/work/LBaaS/docs/workspace.yml
```
- Nếu chưa có `docs` → bắt buộc nhập URL, không có thì **dừng**.
- `reg_init_if_missing` + `reg_set_docs_origin` cập nhật `workspace.yml`.

### [2] Chuẩn bị Codegraph (chỉ khi `CLONE_CODE=1`)
```
── [2] Chuẩn bị Codegraph (@optave/codegraph) ──
  ✓ Node 22 OK
  • Cài codegraph: npm install -g @optave/codegraph
  • Cài engine embed: npm install -g @huggingface/transformers   ← GLOBAL
```

### [3] App repo: clone + build + embed
**(a) Repo đã có trong registry** (do BA khai báo) → hỏi clone từng cái:
```
Registry có repo 'octavia' — clone về máy? [y] ⏎
  • git clone … → octavia
▶ Codegraph build cho repo: …/octavia  (registry name: octavia)
    • Embed (jina-code / structured): …/octavia
  ✓ 'octavia' (branch: main)
```
Mỗi repo: `setup_codegraph_for_repo` chạy `build` → `registry add` → `embed`.

**(b) Khai báo repo mới** (mọi role được ghi; chỉ `CLONE_CODE=1` mới clone):
```
Khai báo thêm một app repo mới? [n] y
Tên repo (vd octavia): octavia-lib
GitLab URL cho 'octavia-lib': git@gitlab.com:fci/octavia-lib.git
Branch cho 'octavia-lib' [main]: ⏎
  ✓ Đã ghi 'octavia-lib' vào registry.
  ✓ 'octavia-lib' clone + build xong
```

### [3.5] Đăng ký MCP multi-repo (nếu đã build ≥ 1 repo)
```
── Đăng ký MCP codegraph (multi-repo) ──
  • claude mcp add codegraph → /Users/…/v22.22.0/bin/codegraph mcp --multi-repo
```
→ Một MCP duy nhất; trong agent gọi tool kèm `repo="octavia"` để chọn repo.

### [4] Cài BMad ở workspace root
Trỏ toàn bộ artifacts/handoff về repo `docs` (qua biến ENV truyền sang `install-bmad.sh`):
```
HANDOFF_FOLDER   = {project-root}/docs/handoff
PROJECT_KNOWLEDGE= {project-root}/docs
PLANNING_ARTIFACTS / IMPL_ARTIFACTS = {project-root}/docs
WORKSPACE_FILE_REL = docs/workspace.yml
```
→ Khi BA tạo PRD/epics/stories, file ghi thẳng vào `docs/` để cả đội thấy qua Git.

### [5] Đồng bộ registry lên repo docs
```
── [5] Đồng bộ registry lên repo docs ──
Commit & push workspace.yml lên repo docs cho đội? [y] ⏎
  → git add/commit/push trong docs/
```
→ Người sau chỉ cần clone `docs` là thấy đầy đủ danh sách repo.

---

## 6. Biến môi trường override

| Biến | Mặc định | Tác dụng |
|---|---|---|
| `TARGET_DIR` | `.` | Thư mục workspace root |
| `ROLE` | (hỏi) | `po`/`ba`/`dev`/`tester` — bỏ bước hỏi |
| `SETUP_BMAD` | `1` | `0` = bỏ bước cài BMad |
| `NODE_VERSION` | `22` | Major Node muốn cài (đừng hạ xuống 20 — vỡ sqlite) |
| `EMBED_MODEL` | `jina-code` | Model embed; đặt **rỗng** để bỏ qua embed |
| `EMBED_STRATEGY` | `structured` | `structured` (dùng graph context) hoặc `source` |
| `WORKSPACE_NAME` | tên thư mục root | Tên workspace ghi vào registry |

Ví dụ — Dev không muốn embed (chỉ cần graph structural):
```bash
EMBED_MODEL= ROLE=dev TARGET_DIR=~/work/LBaaS ./init-workspace.sh
```

---

## 7. Hai kịch bản đầu–cuối

### Kịch bản A — BA khởi tạo dự án mới
```bash
ROLE=ba TARGET_DIR=~/work/LBaaS ./init-workspace.sh
# [1] nhập URL docs (repo docs rỗng vừa tạo trên GitLab)
# [3b] khai báo octavia, octavia-dashboard, octaviaclient
# [5] push workspace.yml → cả đội dùng chung
```

### Kịch bản B — Dev/Tester tham gia sau
```bash
ROLE=dev TARGET_DIR=~/work/LBaaS ./init-workspace.sh
# [1] clone docs → đọc được workspace.yml BA đã push
# [3a] script tự liệt kê octavia/dashboard/client → chọn clone cái cần
#      mỗi repo tự build + embed + vào registry chung
# [3.5] 1 MCP multi-repo sẵn sàng
```

---

## 8. Liên quan & lưu ý

- **Tại sao bắt buộc Node 22?** `@optave/codegraph` đóng gói `better-sqlite3` prebuilt cho
  Node 22. Chạy dưới Node 20 → lỗi `NODE_MODULE_VERSION 115 vs 108` lúc `embed`/truy vấn DB.
- **Engine embed cài global, không vào repo.** `cg_install_engine` chạy `npm install -g`
  trước khi embed; nhờ đó `codegraph embed` resolve được engine và **không** auto-install
  `node_modules`/`package.json` vào thư mục repo.
- **`.codegraph/` nên cho vào `.gitignore`** của mỗi app repo (chứa `graph.db` + vectors, không nên commit).
- **Heads-up:** `install-bmad.sh` hiện vẫn để `NODE_VERSION=20`. BMad không đụng sqlite của
  codegraph nên không lỗi, nhưng nếu muốn đồng nhất Node 22 toàn bộ thì nên nâng luôn.
