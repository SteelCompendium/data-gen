---
status: accepted
date: 2026-04-05
---

# Markdown-first pipeline with HTML round-trip

## Context

The source material is a TTRPG rulebook provided as a single large markdown file. The pipeline needs to split this into hundreds of individual files (one per ability, class, ancestry, etc.) while preserving formatting and hierarchy.

## Options Considered

### Option A: Parse markdown directly with regex/AST
- Pros: No intermediate format, simpler toolchain
- Cons: Markdown parsing is fragile for deep nesting (H7-H9 headers); extracting arbitrary sections by path is hard without a DOM

### Option B: Convert to HTML, extract via XPath, convert back
- Pros: XPath provides reliable, configurable section extraction; HTML is a well-defined DOM; pandoc handles both conversions
- Cons: Round-trip conversion can introduce formatting artifacts; more pipeline stages

## Decision

Option B: round-trip through HTML. Pandoc's markdown-to-HTML and HTML-to-markdown conversions are robust enough, and XPath extraction is far more reliable than regex-based markdown splitting. A Lua filter fixes link extensions during the HTML-to-markdown conversion.

## Consequences

- Pipeline has more stages (MD -> HTML -> section HTML -> section MD), making debugging harder
- HTML Tidy is required to clean up pandoc's HTML output
- Character encoding and entity handling requires explicit normalization at multiple stages
- Section extraction is highly configurable via YAML config files with XPath expressions

## Outcome

Has worked reliably for the Heroes book (400+ pages, hundreds of abilities). The XPath-based extraction handles the complex nesting of Draw Steel's content hierarchy well. The main pain point is HTML entity normalization (smart quotes, special characters).
