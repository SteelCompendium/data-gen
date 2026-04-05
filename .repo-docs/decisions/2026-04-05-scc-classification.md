---
status: accepted
date: 2026-04-05
---

# SCC classification system

## Context

Content from the Draw Steel rulebooks needs a universal, stable identifier that works across different output formats, supports cross-referencing between items, and is both human-readable and machine-processable.

## Options Considered

### Option A: File path as identifier
- Pros: Simple, no extra tooling
- Cons: Coupled to directory structure, not portable across repos, no semantic meaning

### Option B: UUIDs
- Pros: Globally unique, no coordination needed
- Cons: Not human-readable, no hierarchy information, can't derive from content

### Option C: Hierarchical classification (SCC)
- Pros: Human-readable string form (`mcdm.heroes.v1:abilities.fury:gouge`), compact decimal form (`1.1.1:2.4:28`), encodes source, type, and item; supports multiple classifications per item
- Cons: Requires a registration/state system, more complex to implement

## Decision

Option C: Steel Compendium Classification (SCC). The three-component `source:type:item` structure maps naturally to the TTRPG content hierarchy. The dual string/decimal representation serves different use cases (human vs. machine).

## Consequences

- A state file (`classification.json`) tracks the type/source tree and assigned IDs
- Each markdown file gets `scc` and `scdc` frontmatter fields
- Cross-references can use `scc:` protocol links (e.g., `[Gouge](scc:mcdm.heroes.v1:abilities.fury:gouge)`)
- One item can have multiple SCC codes (e.g., an ability classified by class, by level, and globally)
- Decimal codes are positional and depend on registration order

## Outcome

Works well for cross-referencing and downstream consumption. The main challenge is that `classification.json` is regenerated on each run, so decimal codes can shift if source material changes. The string form is stable as long as item names don't change.
