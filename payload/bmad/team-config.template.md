# Team Config

> File này do **mỗi team tự điền** cho project của mình. BMAD Kit không bao giờ ghi đè nó.
> Các agent (`/fci-po`, `/fci-ba`, `/fci-dev`, `/fci-tester`) đọc file này để lấy context riêng.

## Project
- **Tên project**     : [tên]
- **Repo**            : [url git]
- **Mô tả ngắn**      : [1-2 câu]
- **Stack / ngôn ngữ**: [vd Python backend, Node, Go...]

## Git conventions
- **Target / default branch** : [vd main, develop, fci-2025.2-1.0.0]
- **Branch naming**           : [vd feature/<ticket>-<slug>, fix/<slug>]
- **Commit format**           : [vd Conventional Commits: feat/fix/docs(scope): ...]
- **Protected branches**      : [branch không được push thẳng]

## Build / Test / Lint commands
- **Lint** : `[vd tox -e pep8, npm run lint]`
- **Test** : `[vd tox -e py3, npm test]`
- **Run**  : `[lệnh chạy app nếu có]`

## Code patterns / Architecture
> Nếu project có **codegraph MCP**, ưu tiên gọi `codegraph_context` để lấy patterns thật
> thay vì liệt kê thủ công ở đây. Phần dưới chỉ là khung tham khảo.
- API / entrypoint : `[đường dẫn]`
- Business logic   : `[đường dẫn]`
- DB access        : `[đường dẫn / pattern]`
- Models           : `[đường dẫn]`
- Config           : `[đường dẫn]`

## Definition of Done (chung)
- [ ] Code pass lint
- [ ] Unit test pass, coverage ≥ [X]%
- [ ] Không break existing tests
- [ ] Self-review xong
- [ ] PR/MR description đầy đủ

## Ghi chú riêng của team
[bất kỳ convention, gotcha, liên hệ nào khác]
