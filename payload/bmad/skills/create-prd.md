# Skill: Create PRD

## Trigger
Khi PO nhận business requirement và cần tạo PRD.

## Input cần có
- Business requirement (text, email, meeting notes)
- Personas nếu có
- Constraints (deadline, budget, tech)

## Process

### Bước 1: Phân tích requirement
Trả lời 5 câu hỏi trước khi viết:
1. Problem là gì? Ai đang bị ảnh hưởng?
2. Tại sao phải giải quyết bây giờ?
3. Success trông như thế nào?
4. Constraints là gì?
5. Out of scope là gì?

### Bước 2: Xác định Epics
- Nhóm các feature thành Epics lớn
- Mỗi Epic là một vertical slice của value
- Đặt tên: EPIC-[số]-[tên ngắn]

### Bước 3: Viết PRD theo template
Dùng `templates/prd-template.md`

### Bước 4: Review checklist
- [ ] Problem statement rõ ràng
- [ ] Personas được định nghĩa
- [ ] Mỗi Epic có business value rõ
- [ ] Acceptance criteria measurable
- [ ] Out of scope được liệt kê
- [ ] Success metrics có số cụ thể

## Output
- File: `docs/prd/[feature-name]-prd.md`
- Handoff: `handoff/po-to-ba-[feature-name].md`

## Anti-patterns (KHÔNG làm)
- Viết solution thay vì problem
- AC không measurable ("system should be fast")
- Bỏ qua out of scope
- Không có success metrics
