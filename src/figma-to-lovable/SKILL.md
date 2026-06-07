---
name: figma-to-lovable
description: >
  End-to-end workflow: nhận Figma node links (paste trực tiếp HOẶC từ file danh sách)
  → phân tích thiết kế → tạo screen spec artifacts → tổng hợp PRD → tạo Lovable
  build plan hoàn chỉnh với prompts, ảnh, và interaction spec. Trigger bất cứ khi
  nào user cung cấp Figma links, muốn document/implement/prototype từ thiết kế,
  hoặc nói "mô tả design", "tổng hợp PRD", "build plan Lovable", "prototype từ Figma".
  Cũng trigger khi thấy figma.com URL hoặc node-id trong bất kỳ file nào user upload.
---

# Figma → Lovable Workflow Skill

Pipeline có thể áp dụng cho **bất kỳ project** nào: từ Figma design → screen specs
→ PRD → Lovable build plan. Số lượng màn hình, batch, đợt build đều linh hoạt.

---

## Input — Cách Nhận Links

### Cách 1: Paste trực tiếp
```
https://www.figma.com/design/{fileKey}/...?node-id=xx-yy
https://www.figma.com/design/{fileKey}/...?node-id=xx-yy
```

### Cách 2: File danh sách (khuyên dùng cho project lớn)

Upload file `.md`, `.txt`, hoặc `.csv` chứa Figma URLs.

**Format linh hoạt — có hoặc không có section headers:**
```
## Feature: {Tên nhóm tính năng}
https://www.figma.com/design/xxx?node-id=xx-yy  -- mô tả ngắn
https://www.figma.com/design/xxx?node-id=xx-yy  -- mô tả ngắn

## Feature: {Nhóm khác}
https://www.figma.com/design/xxx?node-id=xx-yy
```

**Khi nhận file:**
1. Extract tất cả URLs bằng regex: `https://www\.figma\.com/design/[^\s]+node-id=[^\s]+`
2. Tách `fileKey` và `nodeId` từ mỗi URL
3. Nhóm theo feature nếu file có `##` headers — giúp tổ chức spec tốt hơn
4. Process theo batch nhỏ (5–8 nodes/lần) để tránh timeout
5. Tạo `figma-links-index.md` tự động

### Cách 3: File index từ session trước
Upload `figma-links-index.md` đã có → đọc và tiếp tục hoặc tái sử dụng context.

---

## Key Artifacts

Skill tạo ra các file sau — số lượng tùy quy mô project:

### 🔴 Critical (bắt buộc)

| File | Mô tả | Dùng khi |
|------|-------|---------|
| `lovable-build-plan.md` | Build plan với prompts sẵn, danh sách file đính kèm | Upload lên Lovable |
| `prd/{Project}-PRD.md` | PRD đầy đủ tổng hợp từ tất cả specs | Reference tổng thể |
| `docs/interactions-spec.md` | Hành vi của mọi component (hover/focus/click/tooltip/animation) | Upload đợt cuối |
| `docs/{Project}-Workflow.md` | Navigation flows + click event map | Upload đợt UI wiring |

### 🟡 Important (cần cho Lovable)

| File | Mô tả | Dùng khi |
|------|-------|---------|
| `prd/batches/prd-{nn}-{feature}.md` | PRD chia nhỏ theo feature | Upload từng đợt |
| `figma-screenshots/SCR{nn}-*.png` | Screenshots đặt tên chuẩn | Upload kèm batch |
| `figma-links-index.md` | Index tất cả node IDs với links + descriptions | Tra cứu / tái sử dụng |
| `screenshots-unused-analysis.md` | Ảnh chưa dùng + lý do → dự phòng debug | Debug Lovable |

### 🟢 Supplemental (tra cứu)

| File | Mô tả |
|------|-------|
| `specs/screen-{nn}-*.md` | Screen spec files chi tiết (một file/màn) |
| `docs/{Project}-PRD.docx` | PRD dạng Word cho stakeholders |
| `docs/{Project}-Workflow.docx` | Workflow document dạng Word |
| `tools/download-figma-screenshots.py` | Script tải ảnh từ Figma REST API |
| `README.md` | Quick start guide cho project |

---

## Phase 1 — Thu Thập & Phân Tích Figma

### Quy trình xử lý mỗi node

1. **Gọi song song** `get_screenshot(enableBase64Response=true, maxDimension=1920)` + `get_design_context()`
2. **Phân loại node**: Toàn trang (full-screen) hay component?
3. **Nhóm related nodes** trước khi viết spec
4. **Tạo screen spec file** theo template trong `references/screen-spec-guide.md`

### Quy tắc phân tích

**Focus body content**: Nếu header/sidebar dùng chung một pattern → spec một lần ở màn đầu, các màn sau không lặp lại.

**Xác định state machine** khi thấy nhiều nodes cùng feature:
- 2-3 nodes → thường là `loading | empty | filled`
- 4+ nodes → thêm `action open | error | hover | variant`

**Ground-truth priority**:
Close-up/component screenshot > Full-page screenshot > Design context metadata

**Platform variants**: Khi thấy 2 variants của cùng màn → document bảng diff (Platform A vs B).

**Canvas/overview nodes**: Chỉ dùng để phát hiện tất cả screens có trong design, không document như một màn riêng.

**Responsive nodes**: Nhóm các breakpoints của cùng feature thành một file supplement, không tạo file riêng cho từng breakpoint.

---

## Phase 2 — Tổng Hợp PRD

Trigger khi user nói "tổng hợp" hoặc khi đủ screens để tổng hợp có ý nghĩa.

1. Đọc tất cả `specs/screen-*.md` hiện có
2. Tổng hợp theo cấu trúc được định nghĩa trong `references/prd-structure.md`
3. Lưu `prd/{Project}-PRD.md`
4. Split thành batch files trong `prd/batches/` — số lượng batch tùy project
5. Cập nhật `figma-links-index.md`

---

## Phase 3 — Lovable Build Plan

Tạo `lovable-build-plan.md` với:
- **≤10 files/đợt** (hard limit của Lovable)
- Số lượng đợt tùy độ phức tạp project — không cố định
- Prompt text sẵn để copy-paste
- Paths chính xác đến từng file

Xem `references/lovable-batch-strategy.md` để biết quy tắc batching và các đợt luôn cần thiết.

---

## Phase 4 — Tài Liệu Bổ Sung

Tạo sau khi có PRD, trước khi bắt đầu build trên Lovable:

**`docs/interactions-spec.md`** — Mô tả hành vi của mọi thành phần tương tác trong project.
Xem `references/interaction-spec-template.md` để biết các sections cần cover.

**`docs/{Project}-Workflow.md`** — Navigation flow diagram:
- Tất cả routes
- Click event map cho mỗi trang
- State machines
- Modal/panel behaviors

---

## Cấu Trúc Thư Mục Output

```
outputs/
├── README.md                          ← Quick start
├── lovable-build-plan.md              ← 🔴 MAIN: prompts cho Lovable
├── figma-links-index.md               ← Node ID index
├── screenshots-unused-analysis.md     ← Debug reference
│
├── prd/
│   ├── {Project}-PRD.md               ← Full PRD
│   └── batches/                       ← Split theo feature
│       ├── prd-00-{feature}.md
│       └── prd-{nn}-{feature}.md
│
├── specs/                             ← Screen specs (một file/màn hoặc nhóm)
├── figma-screenshots/                 ← SCR{nn}-{desc}.png
│
├── docs/
│   ├── interactions-spec.md           ← 🔴 Component behaviors
│   ├── {Project}-Workflow.md          ← Navigation flows
│   ├── {Project}-PRD.docx             ← Word version
│   └── {Project}-Workflow.docx
│
└── tools/
    ├── download-figma-screenshots.py
    └── docx_build/
```

---

## Naming Conventions

**Screen specs:** `screen-{nn}-{feature}-{context}.md`
- `{nn}` = số thứ tự tăng dần (01, 02, ...)
- Supplement cùng feature dùng cùng nhóm số
- Ví dụ: `screen-05-{feature}-filled.md` + `screen-06-{feature}-responsive.md`

**Screenshots:** `SCR{nn}{variant}-{feature}-{state}.png`
- `{variant}` = a/b/c nếu có nhiều biến thể cùng số
- `{state}` = loading / empty / filled / hover / error / scroll-left / scroll-right

**PRD batches:** `prd-{nn}-{feature-slug}.md`
- Số thứ tự bắt đầu từ 00 (design system)
- Slug ngắn, lowercase, dấu gạch ngang

---

## Tham Khảo

- `references/screen-spec-guide.md` → Template + quy tắc viết spec
- `r