# Skill: Create Task (Dev)

## Task là gì
Task = đơn vị technical work để implement một Story.
Một Story có thể có nhiều Tasks.

## Khi nào tạo Task
- Sau khi nhận Story từ BA
- Trước khi bắt đầu code
- Để break down implementation plan

## Process

### Bước 1: Đọc codegraph (BẮT BUỘC)
Trước khi tạo task, đọc `CLAUDE.md` và `docs/code-graph/`:
- Xác định modules nào bị ảnh hưởng
- Xác định files cần thay đổi
- Xác định dependencies kỹ thuật
- Xác định patterns cần follow

### Bước 2: Break down thành tasks

TASK-[STORY-ID]-[số]: [Tên Task]
Story    : STORY-[ID]
Type     : Feature / Fix / Refactor / Test / Docs
Estimate : [giờ]
Assignee : [dev name]

#### Mô tả kỹ thuật
[Chi tiết implementation approach]

#### Files cần thay đổi (từ codegraph)
- `[path/to/file].[ext]`  — [lý do]
- `[path/to/file].[ext]`  — [lý do]
- `[path/to/file].[ext]`  — [lý do]

#### Implementation steps
1. [ ] [bước 1]
2. [ ] [bước 2]
3. [ ] [bước 3]

#### Unit test cần viết
- [ ] Test case: [scenario]
- [ ] Test case: [scenario]
- [ ] Mock: [dependencies cần mock]

#### Definition of Done
- [ ] Code pass linting (`[lint command — xem team-config.md]`)
- [ ] Unit test coverage ≥ 80%
- [ ] Không break existing tests (`[test command — xem team-config.md]`)
- [ ] PR description đầy đủ

## Task types
- Feature   : implement new functionality
- Fix       : sửa bug
- Refactor  : cải thiện code không thay đổi behavior
- Test      : viết test cho code đã có
- Docs      : cập nhật documentation
