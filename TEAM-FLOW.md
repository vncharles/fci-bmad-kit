# FCI BMad Kit — Hướng dẫn AI Flow cho Team (PO · BA · Dev · Tester)

Tài liệu này mô tả **cách cả đội dùng các AI agent** để chạy quy trình
**PO → BA → Dev → Tester → PO sign-off** trên một **workspace nhiều repo**, điều phối qua git.

> Đối tượng: PO/BA/Dev/Tester. **PO/BA không cần biết git** — agent làm git thay, bạn chỉ trả lời *có/không*.

---

## 1. Bức tranh tổng thể

Một **dự án** (vd LBaaS) gồm nhiều repo, gom trong **một workspace**:

```
<workspace>/
├── docs/                  ← REPO "docs" = HUB CHIA SẺ (share qua git cho cả đội)
│   ├── workspace.yml      ←   danh sách repo của dự án
│   ├── handoff/           ←   file bàn giao giữa các vai
│   ├── prd/  epics/  stories/  tasks/  test-plans/
│   └── repos/ (tùy)       ←   tài liệu phụ
├── octavia/               ← APP REPO (code) + docs/project-context.md
├── octavia-dashboard/     ← APP REPO (code) + docs/project-context.md
└── _bmad/                 ← bộ agent (cài 1 lần ở workspace root)
```

Nguyên tắc vàng:
- **Mọi tài liệu dùng chung** (PRD, epic, story, task, test-plan, handoff) nằm **trong repo `docs`** → đồng bộ qua GitLab.
- **Code** nằm trong các **app repo** riêng (octavia, octavia-dashboard, …) → đẩy qua branch/MR như bình thường.
- **Tech stack của mỗi app repo** mô tả trong `<app-repo>/docs/project-context.md`.
- **Codegraph** (đọc code thông minh, ít tốn token) chạy **một MCP duy nhất** phục vụ mọi repo; agent chọn repo bằng tham số `repo=<tên>`.

Ai cũng làm việc trên **máy của mình**; trạng thái chung chảy qua repo `docs` trên GitLab.

---

## 2. Cài đặt một lần (mỗi người)

Yêu cầu: máy đã **login GitLab sẵn** (SSH key hoặc đã lưu mật khẩu), đã cài **Node ≥ 20.12**.

```bash
# clone bộ kit này về, vào thư mục workspace (trống) bạn muốn dùng:
ROLE=po   ./init-workspace.sh     # với PO
ROLE=ba   ./init-workspace.sh     # với BA
ROLE=dev  ./init-workspace.sh     # với Dev
ROLE=tester ./init-workspace.sh   # với Tester
```

Script sẽ hỏi vài câu đơn giản (dán URL repo, gõ `y/n`) và tự làm phần còn lại:

| Role | Script clone gì | Codegraph |
|---|---|---|
| **PO** | chỉ `docs` | không (PO không đọc code) |
| **BA / Dev / Tester** | `docs` + (các) app repo | có (tự `codegraph build`) |

- Người **đầu tiên** dựng dự án sẽ *khai báo* các app repo (tên + URL + branch) → ghi vào `docs/workspace.yml` → push.
- Người **sau** chỉ cần dán URL repo `docs`; script đọc `workspace.yml` rồi **hỏi clone repo nào** (BA/Dev/Tester).
- Cuối cùng script hỏi *"commit & push workspace.yml?"* → gõ `y`, script tự đẩy lên cho đội.

Sau khi xong, mở **Claude Code tại thư mục workspace** và dùng lệnh của vai mình:

```
/fci-po    → Thanh (Product Owner)
/fci-ba    → Vanh  (Business Analyst)
/fci-dev   → Zitech (Developer)
/fci-tester→ Hanh  (QA Tester)
```

---

## 3. Mỗi lần dùng agent — nhịp chuẩn (cho mọi vai)

Khi bạn gõ `/fci-*`, agent luôn chạy 3 bước đầu:

1. **Hỏi đồng bộ vào**: *"Pull việc mới nhất của đồng đội từ repo docs?"* → gõ **có** (lấy bản mới nhất). Agent tự `git pull`.
2. **Hỏi bạn làm repo nào**: agent đọc `workspace.yml`, liệt kê repo → bạn chọn (BA/Dev/Tester chọn app repo; PO làm cấp sản phẩm).
3. **Hiện menu** các việc của vai bạn → chọn mã việc (vd `PRD`, `MR`, `DS`, `TP`…).

Khi làm xong và đã tạo/ sửa file trong `docs`:

4. **Hỏi đồng bộ ra**: *"Đẩy kết quả lên repo docs cho đội?"* → gõ **có**. Agent tự `add + commit + push`.
   - Nếu bị từ chối, agent tự `pull --rebase` rồi push lại. Nếu **đụng độ thật** (hiếm) agent dừng và bảo *nhờ Dev/người biết git*.

> **PO/BA chỉ cần trả lời có/không** — không gõ lệnh git bao giờ.

---

## 4. Quy ước file bàn giao (handoff)

Tất cả nằm trong `docs/handoff/` (share qua git):

| Từ → Đến | File |
|---|---|
| PO → BA | `docs/handoff/po-to-ba-[feature].md` |
| BA → PO (hỏi lại) | `docs/handoff/ba-to-po-[feature]-questions.md` |
| PO → BA (phản hồi) | `docs/handoff/po-to-ba-[feature]-feedback.md` |
| BA → Dev | `docs/handoff/ba-to-dev-[feature].md` |
| Dev → Tester | `docs/handoff/dev-to-tester-[story-id].md` |
| Tester → PO (đạt) | `docs/handoff/tester-to-po-[story-id]-approved.md` |
| Tester → Dev (lỗi) | `docs/handoff/tester-to-dev-BUG-[id].md` |

Sản phẩm chính:

| Loại | Nơi lưu |
|---|---|
| PRD | `docs/prd/[feature]-prd.md` |
| Epic | `docs/epics/EPIC-[ID]-[name].md` |
| Story | `docs/stories/EPIC-[ID]/STORY-[ID].md` |
| Task kỹ thuật | `docs/tasks/STORY-[ID]-tasks.md` |
| Test plan | `docs/test-plans/STORY-[ID]-test-plan.md` |
| Tech context mỗi repo | `<app-repo>/docs/project-context.md` |

---

## 5. Luồng tổng thể

```
┌─────────┐   po-to-ba   ┌─────────┐   ba-to-dev   ┌─────────┐  dev-to-tester ┌─────────┐
│   PO    │ ───────────► │   BA    │ ────────────► │   Dev   │ ─────────────► │ Tester  │
│ (Thanh) │              │ (Vanh)  │               │(Zitech) │                │ (Hanh)  │
└────┬────┘              └────┬────┘               └────┬────┘                └────┬────┘
     │  ▲                     │ (hỏi lại nếu mơ hồ)     │                          │
     │  │  tester-to-po       │                         │  ◄── tester-to-dev (BUG) │
     │  └─────────────────────┴─────────────────────────┴──────────────────────────┘
     │                                  PO sign-off → đóng Epic
     ▼
  docs/prd, docs/epics
```

Mỗi mũi tên = một file handoff trong `docs/handoff/`. Người nhận **pull** repo docs là thấy.

---

## 6. Chi tiết từng vai

### 6.1 PO — Thanh (`/fci-po`)
**Mục tiêu:** giá trị nghiệp vụ, viết PRD/Epic, bàn giao BA, duyệt story, sign-off.
**Không:** không nói chi tiết kỹ thuật, không estimate, không đọc code.

| Mã | Việc |
|---|---|
| `PRD` | Viết mới / cập nhật / kiểm tra PRD → `docs/prd/` |
| `CE`  | Tạo Epics từ PRD + breakdown stories |
| `IR`  | Tạo handoff `po-to-ba-[feature].md` (sau khi PRD + Epics sẵn sàng) |
| `CC`  | Duyệt story của BA — accept / reject (kiểm tra AC khớp PRD + có ghi *affected repo*) |
| `SO`  | Sign-off sau khi Tester xác nhận → đóng Epic |

**Lưu ý đa-repo:** PO đọc `workspace.yml` để biết dự án có những app repo nào, và **ghi rõ feature đụng repo nào** trong PRD/Epic để BA/Dev biết.

**Nhịp:** vào → *pull? có* → viết PRD (`PRD`) → tạo Epic (`CE`) → tạo handoff cho BA (`IR`) → *push? có*. Báo BA (ping Slack).

---

### 6.2 BA — Vanh (`/fci-ba`)
**Mục tiêu:** biến handoff của PO thành **User Story rõ ràng, đầy đủ** (chuẩn INVEST), không còn câu hỏi mở trước khi giao Dev.
**Không:** không quyết tech stack, không viết code, không viết test case.

| Mã | Việc |
|---|---|
| `BP` | Đọc & phân tích handoff PO (`po-to-ba-*`) + PRD + project-context của app repo liên quan |
| `MR` | Viết User Stories từ Epic (chuẩn INVEST) → `docs/stories/` |
| `DR` | Refine Epics + breakdown stories |
| `TR` | Tạo file câu hỏi clarification cho PO (`ba-to-po-*-questions.md`) |
| `CB` | Checklist review story trước khi giao Dev (≤8 điểm, AC happy/edge/error, ghi *affected repo*) |
| `WB` | Tạo handoff `ba-to-dev-[feature].md` sau khi PO duyệt |
| `DP` | Soát các story hiện có để tránh trùng lặp |

**Lưu ý đa-repo:** lúc activate BA chọn app repo story đụng tới (có thể nhiều repo). BA dùng **codegraph (`repo=<tên repo>`)** để nắm ràng buộc kỹ thuật và ước lượng độ lớn story — **vẫn không viết code**. BA đọc `<repo>/docs/project-context.md`.

**Nhịp:** vào → *pull? có* → `BP` → (nếu mơ hồ: `TR`, chờ PO) → `MR`/`DR` → `CB` → `WB` → *push? có*. Báo Dev.

---

### 6.3 Dev — Zitech (`/fci-dev`)
**Mục tiêu:** code sạch, có test, theo pattern sẵn có; phân tích blast-radius bằng codegraph trước khi đụng code.
**Không:** không đổi AC (hỏi BA), không merge khi test fail, không hardcode, không push thẳng nhánh bảo vệ.

| Mã | Việc |
|---|---|
| `DS` | Nhận story → chạy full: phân tích → tasks → implement → handoff |
| `QD` | Quick dev: clarify → plan → implement → review |
| `AN` | **Phân tích story bằng codegraph** (`repo=<repo>`): context → search → impact → deps. Báo modules/file bị ảnh hưởng, estimate, rủi ro |
| `CT` | Break story thành tasks kỹ thuật → `docs/tasks/` |
| `BC` | **Bootstrap `<repo>/docs/project-context.md`** bằng document-project + codegraph (chạy khi repo chưa có) |
| `HO` | Tạo handoff `dev-to-tester-[story-id].md` (branch, cách test, file đổi, edge cases) |
| `CR` | Code review toàn diện trước khi push |
| `IN` | Điều tra bug / hành vi lạ (evidence-graded) |

**Lưu ý đa-repo (feature đụng 2 repo):** làm **tuần tự từng repo trong cùng một phiên** — chọn `octavia`, `AN` với `repo=octavia`, code; rồi chuyển `octavia-dashboard`, `AN` với `repo=octavia-dashboard`, code. Codegraph index **từng repo riêng** nên gọi từng repo một (`list_repos` để xem repo nào đã đăng ký).

**Git:** tasks/handoff trong `docs` thì agent hỏi *push? có*. **Code** thì Dev tự commit/push ở app repo qua **branch/MR** như thường lệ (đây là việc của Dev, không qua repo docs).

**Nhịp:** vào → *pull? có* → chọn repo → `AN` → `CT` → implement (`DS`/`QD`) → `CR` → `HO` → *push docs? có* → push code app repo (branch/MR). Báo Tester.

---

### 6.4 Tester — Hanh (`/fci-tester`)
**Mục tiêu:** cổng chất lượng trước release. Viết test plan từ AC, chạy mọi case, báo kết quả (đạt → PO, fail → Dev kèm bug report).
**Không:** không sửa bug (báo Dev), không bỏ case, không sign-off khi còn bug Critical/High, không test trên production.

| Mã | Việc |
|---|---|
| `TP` | Viết Test Plan từ Story AC + handoff Dev (dùng codegraph `repo=<repo>` để biết chỗ cần test) → `docs/test-plans/` |
| `EX` | Chạy từng test case, ghi kết quả Pass/Fail + bằng chứng |
| `PA` | Tạo handoff `tester-to-po-[story-id]-approved.md` khi tất cả pass |
| `BUG` | Tạo bug report `tester-to-dev-BUG-[id].md` khi fail (severity, steps, expected/actual, evidence) |
| `AT` | Sinh test tự động API/E2E cho story/feature |
| `RV` | Review chất lượng test case hiện có |
| `TR` | Trace coverage — map AC ↔ test + quyết định quality gate |

**Nhịp:** vào → *pull? có* → chọn repo → `TP` → `EX` → nếu đạt `PA` (→PO), nếu fail `BUG` (→Dev) → *push? có*. Báo PO hoặc Dev.

---

## 7. Ví dụ xuyên suốt — feature đụng 2 repo

Feature: **"Thêm health-check weight cho LB pool"** (đụng `octavia` backend + `octavia-dashboard` UI).

1. **PO** `/fci-po`: *pull* → `PRD` (viết `docs/prd/health-check-weight-prd.md`, ghi *affected: octavia + octavia-dashboard*) → `CE` → `IR` (handoff) → *push*. Ping BA.
2. **BA** `/fci-ba`: *pull* → chọn 2 repo → `BP` (dùng codegraph `repo=octavia` & `repo=octavia-dashboard` để hiểu ràng buộc) → `MR` (viết story `docs/stories/...`, mỗi story ghi repo bị đụng) → `CB` → `WB` → *push*. Ping Dev.
3. **Dev** `/fci-dev`: *pull* →
   - chọn `octavia` → `AN` (`repo=octavia`) → `CT` → code backend → `CR`
   - chọn `octavia-dashboard` → `AN` (`repo=octavia-dashboard`) → code UI → `CR`
   - `HO` (handoff) → *push docs* → push code 2 app repo qua branch/MR. Ping Tester.
4. **Tester** `/fci-tester`: *pull* → `TP` → `EX` → đạt: `PA` (→PO) / fail: `BUG` (→Dev) → *push*.
5. **PO** `/fci-po`: *pull* → `SO` (đối chiếu success metrics trong PRD) → đóng Epic → *push*.

---

## 8. Codegraph — vì sao nhanh & ít token

- Index code dựng sẵn; agent hỏi codegraph trả về **symbol / impact / dependency** thay vì đọc nguyên file → tiết kiệm token.
- **Một MCP** phục vụ mọi repo; chọn codebase bằng `repo=<tên>`; `list_repos` xem repo đã đăng ký.
- Khi **code đổi nhiều**, chạy lại để graph chính xác: `codegraph build <đường-dẫn-repo>` (hoặc `codegraph watch <repo>`).

**Giới hạn cần nhớ:**
- Codegraph **không nối lời gọi chéo repo** (vd dashboard gọi API octavia) → ranh giới đó mô tả trong PRD/story/`project-context.md`.
- Mỗi lệnh codegraph nhắm **một repo**; đụng 2 repo thì gọi 2 lần.

---

## 9. Quy ước phối hợp đội

- **Git không tự báo**: sau mỗi handoff, **ping Slack/GitLab** cho người nhận biết mà *pull*.
- **Luôn trả lời "có" khi agent hỏi pull/push** — để không lệch bản với đồng đội.
- **Tránh đụng độ**: mỗi vai ghi thư mục riêng (PO→`prd/epics`, BA→`stories`, Dev→`tasks`, Tester→`test-plans`) nên hiếm khi conflict. Nếu agent báo conflict thật → nhờ Dev xử lý.
- **PO/BA** không cần cài/đụng codegraph hay git; **Dev/Tester** phụ trách phần kỹ thuật (codegraph build lại, xử lý conflict khi cần).

---

## 10. Cheat-sheet

| Vai | Lệnh | Việc thường dùng |
|---|---|---|
| PO | `/fci-po` | `PRD` → `CE` → `IR` → `CC` → `SO` |
| BA | `/fci-ba` | `BP` → `MR`/`DR` → `CB` → `WB` (mơ hồ: `TR`) |
| Dev | `/fci-dev` | `AN` → `CT` → `DS`/`QD` → `CR` → `HO` (mới repo: `BC`) |
| Tester | `/fci-tester` | `TP` → `EX` → `PA` (đạt) / `BUG` (fail) |

Mỗi phiên: **pull? có** (đầu) → chọn repo → làm việc theo menu → **push? có** (cuối) → ping người kế tiếp.
