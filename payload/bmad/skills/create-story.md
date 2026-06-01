# Skill: Create Story

## Story là gì (chuẩn BMAD)
User Story = đơn vị nhỏ nhất của work mang lại value.
Một story phải hoàn thành trong 1 sprint.

## INVEST principle (bắt buộc)
- Independent  : Story không phụ thuộc story khác
- Negotiable   : Details có thể thay đổi
- Valuable     : Mang lại value cho user
- Estimable    : Dev có thể estimate được
- Small        : Hoàn thành trong 1 sprint
- Testable     : Tester có thể verify được

## Format chuẩn

STORY-[EPIC-ID]-[số]: [Tên Story]
Epic   : EPIC-[ID]
Priority: P1 / P2 / P3
Points : [fibonacci: 1, 2, 3, 5, 8, 13]
Status : Draft / Ready / In Progress / Done

### User Story
As a [persona cụ thể],
I want [action cụ thể],
So that [benefit cụ thể — business value].

### Context & Background
[Thông tin cần thiết để Dev/Tester hiểu]

### Acceptance Criteria
(Gherkin format)

**Scenario 1: [Happy path]**
Given [precondition]
When  [action]
Then  [expected result]

**Scenario 2: [Edge case]**
Given [precondition]
When  [action]
Then  [expected result]

**Scenario 3: [Error case]**
Given [precondition]
When  [action]
Then  [expected result]

### Technical Notes
[Gợi ý technical nếu BA biết — không bắt buộc]
[API endpoints liên quan nếu có]

### UI/UX Notes
[Mockup link hoặc mô tả nếu có]

### Definition of Done
- [ ] Code hoàn thành + reviewed
- [ ] Unit test viết và pass
- [ ] AC được verify bởi Tester
- [ ] No critical bugs
- [ ] Documentation cập nhật nếu cần

### Dependencies
- Cần story: [STORY-ID] hoàn thành trước
- Blocked by: [nếu có]

### Notes / Open Questions
- [câu hỏi cần clarify với PO]

## Checklist trước khi handoff sang Dev
- [ ] Story đủ nhỏ (≤ 8 points)
- [ ] AC viết đủ: happy + edge + error cases
- [ ] Technical notes có nếu cần
- [ ] Dependencies rõ ràng
- [ ] Open questions đã được resolve

## Anti-patterns
- "As a user" quá chung → phải dùng persona cụ thể
- AC quá chung: "should work correctly"
- Story > 13 points → phải split
- Không có error case trong AC
