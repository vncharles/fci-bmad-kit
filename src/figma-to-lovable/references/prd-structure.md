# PRD Structure Guide

## Cấu Trúc Tổng Quát

PRD được tổng hợp từ tất cả screen specs. Số sections phụ thuộc vào độ phức tạp project.

**Sections bắt buộc (mọi project):**
1. Product Overview
2. Information Architecture (routes, page hierarchy)
3. Design Tokens (colors, typography, spacing, shadows)
4. Global Components (shared: header, sidebar, pagination, toast, modal, spinner, form fields)
5. {Mỗi feature/page chính → 1 section}
6. Responsive Rules
7. TypeScript Master Types
8. API Patterns & State Machines
9. Design Corrections Log

**Sections tùy chọn (thêm nếu project cần):**
- Platform Variants (nếu có A/B platform)
- Permission & Access Control
- Localization / Multi-language
- Analytics & Tracking events

---

## Cách Viết Từng Section

### Design Tokens (Section 3)

Trích xuất từ close-up/component screenshots:
```markdown
## 3.1 Colors
- Primary: {hex}
- Success bg/text: {hex}/{hex}
- Warning bg/text: {hex}/{hex}
- Error bg/text: {hex}/{hex}
- Gray scale: {hex} (50) → {hex} (900)

## 3.2 Typography
- Body: {size}px / {weight} / {color}
- Heading: {size}px / {weight}
- Label: {size}px / {weight}
- Helper text: {size}px / {color}

## 3.3 Spacing & Radius
- Border radius: sm {n}px / md {n}px / lg {n}px / pill 9999px

## 3.4 Status Badges (project-specific)
| Status | Background | Dot | Text | Shape |
```

### Global Components (Section 4)

```markdown
## 4.1 Header ({height}px, bg {hex})
Elements: {list left→right}

## 4.2 Sidebar ({width}px, bg {hex})
Default: visible at ≥{breakpoint}px, hidden below
Nav structure: {describe groups and active states}

## 4.3 Pagination
Format: "1–N of Total  N/page ▾  ← Prev  pages  Next →"

## 4.4 Toast
Position: fixed top:{n}px right:{n}px
Auto-dismiss: {n}s

## 4.5 Modal
Backdrop: rgba(0,0,0,{opacity})
Card: {width}px, radius {n}px

## 4.6 Form Fields
{All states: default/hover/focus/error/disabled}
```

### Feature Pages (Section 5+)

Mỗi page/feature:
```markdown
## N. {Feature Name}

### N.1 States
| State | Trigger | Content |
|-------|---------|---------|
| loading | ... | spinner |
| empty | ... | illustration + CTA |
| filled | ... | table/content |

### N.2 Table Columns (nếu có)
| # | Column | Width | Notes |
| Sticky: {left col} (left), {right col} (right) |
| min-width: {n}px |

### N.3 Actions
| Action | Condition | Result |
```

### API Patterns (Section N+2)

```markdown
## Sync Operations (immediate confirmation)
Toast: "{Entity} created/deleted successfully"
Examples: {list from project}

## Async Operations (background processing)
Toast: "Successfully requested to {action}..."
Status transition: {entity} → {In-Progress state} → {Final state}
Examples: {list from project}
```

### Design Corrections Log (Section N+3)

```markdown
| Location | Design shows | Implement as | Reason |
|----------|-------------|--------------|------