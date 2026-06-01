# Feature Development Workflow

## Flow tổng quan

PO → BA → DEV → TESTER → PO (sign-off)

---

## Bước 1: PO — Tạo PRD + Epics

Agent  : `.bmad/agents/po-agent.md`
Skills : `create-prd.md`, `create-epic.md`
Input  : Business requirement
Output :
  - `docs/prd/[feature]-prd.md`
  - `docs/epics/EPIC-[ID]-[name].md`
Handoff: `handoff/po-to-ba-[feature].md`

---

## Bước 2: BA — Phân tích + Viết Stories

Agent  : `.bmad/agents/ba-agent.md`
Skills : `create-story.md`
Input  : PRD + Epics
Output : `docs/stories/EPIC-[ID]/STORY-[ID].md`

Nếu cần clarify:
→ `handoff/ba-to-po-[feature]-questions.md`
→ Chờ PO trả lời trước khi tiếp tục

Handoff: `handoff/ba-to-dev-[feature].md`

---

## Bước 3: Dev — Implement

Agent  : `.bmad/agents/dev-agent.md`
Skills : `create-task.md`
Input  : Stories + codegraph (`CLAUDE.md`)
Output :
  - `docs/tasks/STORY-[ID]-tasks.md`
  - Code + unit tests
  - PR trên Git

Handoff: `handoff/dev-to-tester-[story-id].md`

---

## Bước 4: Tester — Verify

Agent  : `.bmad/agents/tester-agent.md`
Skills : `create-test-plan.md`
Input  : Code + AC + handoff từ Dev
Output : `docs/test-plans/STORY-[ID]-test-plan.md`

Nếu Pass → `handoff/tester-to-po-[story-id]-approved.md`
Nếu Fail → `handoff/tester-to-dev-BUG-[id].md` → quay Bước 3

---

## Bước 5: PO — Sign-off

Input  : Test result + handoff approved
Action : Verify với success metrics trong PRD
Output : Update Epic status → Done
         Merge branch → target branch (xem `team-config.md`)

---

## Handoff folder convention

| File                                    | Từ     | Đến     |
|-----------------------------------------|--------|---------|
| `po-to-ba-[feature].md`                 | PO     | BA      |
| `ba-to-po-[feature]-questions.md`       | BA     | PO      |
| `ba-to-dev-[feature].md`                | BA     | Dev     |
| `dev-to-tester-[story-id].md`           | Dev    | Tester  |
| `tester-to-dev-BUG-[id].md`             | Tester | Dev     |
| `tester-to-po-[story-id]-approved.md`   | Tester | PO      |
