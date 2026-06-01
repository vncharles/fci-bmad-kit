Kiểm tra trạng thái hiện tại của BMAD workflow cho project này.

Thực hiện theo thứ tự:

1. **Handoff pending** — Liệt kê tất cả files trong `handoff/` (nếu có), nhóm theo:
   - PO → BA (po-to-ba-*)
   - BA → PO (ba-to-po-*)
   - BA → Dev (ba-to-dev-*)
   - Dev → Tester (dev-to-tester-*)
   - Tester → Dev - bugs (tester-to-dev-BUG-*)
   - Tester → PO - approved (tester-to-po-*-approved*)

2. **Docs snapshot** — Liệt kê files trong:
   - `docs/prd/` — PRDs
   - `docs/epics/` — Epics
   - `docs/stories/` — Stories (theo EPIC-ID/)
   - `docs/tasks/` — Task breakdowns
   - `docs/test-plans/` — Test plans

3. **Summary** — Tóm tắt:
   - Bao nhiêu Epics / Stories / Tasks đang active?
   - Ai cần làm gì tiếp theo? (dựa vào handoff pending)
   - Có bottleneck ở đâu không?
