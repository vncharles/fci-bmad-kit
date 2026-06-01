# Skill: Create Test Plan

## Process

### Bước 1: Đọc AC từ Story
- Mỗi AC scenario = ít nhất 1 test case
- Cần cover: happy path, edge case, error case

### Bước 2: Xác định test levels
- Unit test        : Dev tự viết
- Integration test : Tester + Dev phối hợp
- E2E test         : Tester chịu trách nhiệm
- Regression       : Tester chạy trước release

### Bước 3: Viết test plan

TEST-PLAN-[STORY-ID]
Story       : STORY-[ID]
Tester      : [tên]
Environment : [dev / staging / prod]

#### Test Scope
In scope:
- [feature/function cần test]

Out of scope:
- [không test trong scope này]

#### Test Cases

**TC-[ID]-01: [Tên — Happy Path]**
- Priority     : P1
- Type         : Functional / Integration / E2E
- Precondition : [setup cần thiết]
- Test data    : [data cụ thể]
- Steps:
  1. [bước 1]
  2. [bước 2]
- Expected result : [kết quả cụ thể, measurable]
- Actual result   : [điền sau khi test]
- Status          : Pass / Fail / Blocked

**TC-[ID]-02: [Edge Case]**
[tương tự format trên]

**TC-[ID]-03: [Error Case]**
[tương tự format trên]

#### Automation plan
- [ ] TC-[ID]-01 : automate với [framework]
- [ ] TC-[ID]-02 : manual — [lý do]

#### Risk & Mitigation
- Risk       : [rủi ro khi test]
- Mitigation : [cách xử lý]

#### Entry criteria
- [ ] Code đã deploy lên môi trường test
- [ ] Unit test đã pass
- [ ] Test data đã chuẩn bị

#### Exit criteria
- [ ] Tất cả P1 test cases pass
- [ ] Không có Critical/High bugs open
- [ ] PO đã review kết quả
