Tạo handoff file giữa các roles trong BMAD workflow.

Argument: $ARGUMENTS (format: "[from]-to-[to] [feature/story-id]")
Ví dụ: /bmad-handoff po-to-ba load-balancer-timeout

Dựa vào argument:

**po-to-ba**: Tạo `handoff/po-to-ba-[feature].md`
- Tóm tắt PRD đã viết
- Link đến file PRD + Epics
- Câu hỏi cần BA clarify
- Priority và deadline nếu có

**ba-to-dev**: Tạo `handoff/ba-to-dev-[feature].md`
- List stories đã ready (với link)
- Story nào priority cao nhất
- Technical notes BA muốn nhấn mạnh
- Open questions đã resolve

**dev-to-tester**: Tạo `handoff/dev-to-tester-[story-id].md`
- Story ID + branch name + PR link
- How to test (setup instructions)
- Files thay đổi
- Edge cases cần chú ý
- Known limitations

**tester-to-po**: Tạo `handoff/tester-to-po-[story-id]-approved.md`
- Story approved
- Test cases X/X passed
- Sign-off info

**tester-to-dev**: Tạo `handoff/tester-to-dev-BUG-[id].md`
- Bug report đầy đủ (severity, steps, expected vs actual, evidence)

Nếu không có argument, hỏi user muốn tạo handoff từ role nào sang role nào.
