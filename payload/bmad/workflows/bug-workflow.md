# Bug Fix Workflow

## Flow

TESTER / USER báo bug → DEV fix → TESTER verify → PO close

---

## Bước 1: Tạo Bug Report

Ai  : Tester hoặc bất kỳ ai phát hiện
File: `handoff/tester-to-dev-BUG-[id].md`

Điền đủ:
- Severity + Priority
- Steps to reproduce
- Expected vs Actual
- Evidence (log/screenshot)
- Environment info

---

## Bước 2: Dev nhận và fix

1. Đọc bug report
2. Đọc `CLAUDE.md` để xác định root cause
3. Tạo branch: `fix/BUG-[ID]-[short-desc]`
4. Fix + viết regression test
5. Tạo handoff: `handoff/dev-to-tester-BUG-[id]-fixed.md`

---

## Bước 3: Tester verify fix

1. Đọc handoff từ Dev
2. Re-run test case gốc
3. Chạy regression nếu là Critical/High

Pass → `handoff/tester-to-po-BUG-[id]-closed.md`
Fail → update bug report, quay Bước 2

---

## Bước 4: PO close

- Review bug closed
- Merge fix branch
- Update release notes nếu cần
