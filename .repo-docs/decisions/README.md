# Decision Log

A running record of architectural and design decisions made in this project.

## Why log decisions?

Context doesn't survive in memory. Logging decisions prevents relitigating past choices and helps new contributors understand why things are the way they are.

## What to log

Every decision: library choices, format changes, rejected approaches, conventions, reverted experiments. Small decisions compound -- logging them builds a navigable history.

## How to create a record

1. Copy the template below
2. Name the file `YYYY-MM-DD-short-description.md`
3. Fill in all sections
4. Set status to `proposed`, `accepted`, `tried`, `superseded`, or `deprecated`

### Template

```markdown
---
status: proposed
date: YYYY-MM-DD
---

# Title

## Context

Why was this decision needed?

## Options Considered

### Option A
- Pros: ...
- Cons: ...

### Option B
- Pros: ...
- Cons: ...

## Decision

What was chosen and why.

## Consequences

Positive outcomes and accepted tradeoffs.

## Outcome

Leave blank until there is real experience to report.
```

### Status definitions

| Status | Meaning |
|--------|---------|
| `proposed` | Under consideration, not yet implemented |
| `accepted` | Agreed upon and implemented |
| `tried` | Implemented but didn't work; reverted or abandoned |
| `superseded` | Replaced by a newer decision |
| `deprecated` | Still in place but scheduled for removal |

## Index

| Date | Decision | Status |
|------|----------|--------|
| 2026-04-05 | [Markdown-first pipeline with HTML round-trip](2026-04-05-markdown-html-roundtrip.md) | accepted |
| 2026-04-05 | [Just as pipeline orchestrator](2026-04-05-just-as-orchestrator.md) | accepted |
| 2026-04-05 | [SCC classification system](2026-04-05-scc-classification.md) | accepted |
| 2026-04-05 | [Multiple output variants](2026-04-05-multiple-output-variants.md) | accepted |
