# Data-Gen CLAUDE.md

## What this project does

Converts Draw Steel TTRPG source documents (markdown) into structured data formats (JSON, YAML, MD variants)
and publishes them to separate `data-*` git repos under the Steel Compendium umbrella.

## Tooling

- **Devbox** manages the dev environment. Run `devbox shell` from `etl/` to get all tools.
- **just** (justfiles) orchestrates the entire ETL pipeline from `etl/`.
- **Python 3.13** (.venv) for inline scripts embedded in justfiles and standalone `.py` files.
- **Pandoc** for markdown-to-html conversion.
- **html-tidy** for HTML cleanup.
- **sc-convert** (from `steel-compendium-sdk` npm package) for feature/statblock format conversion.
- **mdformat** for markdown linting/formatting.

## Justfile conventions

- Root orchestrator: `etl/justfile`
- Shared variables and utility recipes: `etl/_utils.just`
- **Always use `import '_utils.just'`** in modules that need shared state. Never use `mod` for it.
  Backtick subprocess calls to root recipes from module variable assignments cause infinite recursion.
- Top-level modules (heroes, monsters, adventures, unified) are loaded via `mod` in the root justfile.
- Utility modules (aggregate, features, markdown, html, linker, etc.) are also loaded via `mod`.
- All justfiles set `export BASH_ENV := ".utils/.utilsrc"` and `set shell := ["bash", "-c"]`.
- Many recipes contain embedded Python3 scripts (not separate .py files).

## Pipeline flow

1. Source markdown (e.g. `input/heroes/Draw Steel Heroes.md`) is converted to HTML via Pandoc.
2. HTML is split into sections using xpath-based extraction (configured by YAML in `input/heroes/*.yml`).
3. HTML sections are converted back to individual markdown files.
4. Frontmatter/metadata is generated (SCC classification, type-specific metadata).
5. Indexes are generated for each section directory.
6. Markdown is formatted, linked (SCC links applied/removed), and linted.
7. Final markdown is converted to JSON/YAML/DSE variants.
8. Output is copied to `data-*` repos via `_copy_data_to_repo`.
9. `unified.just` assembles all book outputs into combined `data-md` repos.

## Key directories

- `etl/` -- All justfiles and conversion logic
- `input/` -- Source documents and section config YAML files
- `staging/` -- Intermediate build artifacts (wiped on each run)
- `../data-*` -- Sibling repos that receive final output

## SCC (Steel Compendium Classification)

Hierarchical classification system: `source:type:item` (e.g. `mcdm.heroes.v1:abilities.fury:gouge`).
Has both string and decimal forms. See `etl/README.md` for full spec.
