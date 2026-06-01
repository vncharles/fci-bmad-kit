# TEST-PLAN-[STORY-ID]

Story       : STORY-[ID]
Tester      : [tên]
Environment : dev / staging
Date        : [YYYY-MM-DD]

---

## Test Scope

**In scope:**
- [feature/function cần test]

**Out of scope:**
- [không test trong scope này]

## Entry criteria

- [ ] Code đã deploy lên môi trường test
- [ ] Unit test đã pass (`[test command — xem team-config.md]`)
- [ ] Test data đã chuẩn bị

## Test Cases

**TC-[ID]-01: [Tên — Happy Path]**
- Priority     : P1
- Type         : Functional / Integration / E2E
- Precondition : [setup cần thiết]
- Test data    : [data cụ thể]
- Steps:
  1. [bước 1]
  2. [bước 2]
- Expected result : [kết quả cụ thể, measurable]
- Actual result   : _(điền sau khi test)_
- Status          : Pass / Fail / Blocked

---

**TC-[ID]-02: [Edge Case]**
- Priority     : P2
- Type         : Functional
- Precondition : [setup]
- Test data    : [data]
- Steps:
  1. [bước 1]
- Expected result : [kết quả]
- Actual result   : _(điền sau khi test)_
- Status          : Pass / Fail / Blocked

---

**TC-[ID]-03: [Error Case]**
- Priority     : P2
- Type         : Functional
- Precondition : [setup]
- Test data    : [data]
- Steps:
  1. [bước 1]
- Expected result : [error message / HTTP status cụ thể]
- Actual result   : _(điền sau khi test)_
- Status          : Pass / Fail / Blocked

---

## Automation plan

- [ ] TC-[ID]-01 : automate với [framework/tox]
- [ ] TC-[ID]-02 : manual — [lý do]

## Risk & Mitigation

| Risk | Mitigation |
|------|------------|
| [rủi ro] | [cách xử lý] |

## Exit criteria

- [ ] Tất cả P1 test cases pass
- [ ] Không có Critical/High bugs open
- [ ] PO đã review kết quả

## Summary

| Total | Pass | Fail | Blocked |
|-------|------|------|---------|
| [n] | [n] | [n] | [n] |
