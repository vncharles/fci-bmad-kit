# Skill: Create Epic

## Epic là gì (chuẩn BMAD)
Một Epic là một large body of work có thể chia thành Stories.
Epic = một capability hoàn chỉnh mang lại value cho user.

## Khi nào tạo Epic
- Feature quá lớn, cần nhiều sprint
- Có nhiều user journeys liên quan
- Cần nhiều team/role phối hợp

## Format chuẩn

EPIC-[ID]: [Tên Epic]

### Mục tiêu
[1-2 câu mô tả business goal]

### Business Value
[Tại sao Epic này quan trọng — dùng số nếu được]

### User Personas
- [Persona 1]: [nhu cầu cụ thể]
- [Persona 2]: [nhu cầu cụ thể]

### Scope
In scope:
- [capability 1]
- [capability 2]

Out of scope:
- [explicitly excluded]

### Stories thuộc Epic này
- STORY-[EPIC-ID]-01: [tên]
- STORY-[EPIC-ID]-02: [tên]
- STORY-[EPIC-ID]-03: [tên]

### Definition of Done
- [ ] Tất cả stories hoàn thành
- [ ] E2E test pass
- [ ] Performance đạt target
- [ ] Documentation cập nhật
- [ ] PO sign-off

### Dependencies
- Phụ thuộc: [Epic/system khác nếu có]
- Blocked by: [nếu có]

### Timeline estimate
- Story points: [tổng]
- Sprint estimate: [X sprints]

## Quy tắc đặt ID
EPIC-001, EPIC-002... theo thứ tự tạo

## Checklist trước khi handoff sang BA
- [ ] Epic có business value rõ ràng
- [ ] Scope được define (in/out)
- [ ] Ước tính số stories hợp lý (3-10 stories/epic)
- [ ] Dependencies được liệt kê
- [ ] DoD được define
