---
repo: data-gen
type: tool
status: active
tech:
  - just (task runner)
  - bash (ETL scripts)
  - python (frontmatter, classification, linking)
  - pandoc (markdown/html conversion)
  - devbox (environment management)
updated: 2026-04-05
---

# data-gen

ETL pipeline that converts Draw Steel TTRPG source documents (markdown) into structured, multi-format output distributed across multiple `data-*` repos. Part of the Steel Compendium project.

**This repo is not:** a data repo itself, a web application, or a content authoring tool. It processes existing markdown source documents and outputs to sibling `data-*` repos.

## Quick Reference

| Action | Command |
|--------|---------|
| Enter dev environment | `devbox shell` (from `etl/` directory) |
| Generate all outputs | `devbox run gen` or `just gen` (from `etl/`) |
| Generate heroes only | `devbox run gen_heroes` or `just gen_heroes` |
| Generate monsters only | `just gen_monsters` |
| Convert PDF to markdown | `just convert_heroes` (from `pdf_to_md/`, requires `OPEN_AI_KEY`) |
| Switch data repo branches | `just switch_repos_to <branch>` |

| Resource | URL |
|----------|-----|
| Repository | https://github.com/SteelCompendium/data-gen |
| Bug reports | [Google Form](https://docs.google.com/forms/d/e/1FAIpQLSc6m-pZ0NLt2EArE-Tcxr-XbAPMyhu40ANHJKtyRvvwBd2LSw/viewform) |
| Issue tracker | https://github.com/SteelCompendium/data-gen/issues |

## Repo Structure

```
data-gen/
  input/                    # Source material and config
    heroes/                 # Heroes book markdown + section config YAMLs
      Draw Steel Heroes.md  # Primary source document
      abilities.yml         # Section extraction config
      classes.yml           # Section extraction config
      ...                   # Other section configs
    monsters/               # Monsters book markdown + section configs
      Draw Steel Monsters.md
      monsters.yml
    classification.json     # SCC type/source tree state
  etl/                      # ETL pipeline (justfiles + scripts)
    justfile                # Main entry point
    heroes.just             # Heroes book pipeline
    monsters.just           # Monsters book pipeline
    adventures.just         # Adventures pipeline (stub)
    unified.just            # Unification across books
    html.just               # HTML conversion utilities
    markdown.just           # Markdown conversion/linting
    features.just           # Feature extraction and conversion
    statblocks.just         # Statblock conversion
    sc_classification.just  # SCC classification generation
    frontmatter.just        # Frontmatter processing
    linker.just             # SCC link application/removal
    index.just              # Index file generation
    aggregate.just          # Aggregate data file generation
    link_md/                # Obsidian-style auto-linker (Python)
    pre_automation_tools/   # Legacy pre-processing helpers
    devbox.json             # Dev environment packages
  pdf_to_md/                # PDF-to-markdown converter (uses marker + OpenAI)
    justfile
    devbox.json
  staging/                  # Generated intermediate files (gitignored)
```

## Reading Guide by Role

### Human Roles

| Role | Start here | Then read |
|------|-----------|-----------|
| **New to this repo** | This file | [project.md](project.md) |
| **Developer** | [development.md](development.md) | [architecture.md](architecture.md), [conventions.md](conventions.md) |
| **Architect** | [architecture.md](architecture.md) | [integration.md](integration.md), [decisions/](decisions/) |
| **DevOps / SRE** | [development.md](development.md) | [integration.md](integration.md) |

### Agent Roles

| Agent Role | Start here | Then read |
|------------|-----------|-----------|
| **Code review** | [conventions.md](conventions.md) | [architecture.md](architecture.md) |
| **Bug fix / debug** | [troubleshooting.md](troubleshooting.md) | [development.md](development.md), [architecture.md](architecture.md) |
| **Feature implementation** | [architecture.md](architecture.md) | [conventions.md](conventions.md), [development.md](development.md), [decisions/](decisions/) |
| **Documentation** | This file | [project.md](project.md), [architecture.md](architecture.md) |
| **Onboarding / Q&A** | This file | [project.md](project.md), [development.md](development.md) |

## Current Status

- **Health:** Active development
- **Last significant change:** Aggregate files for JSON/YAML, SCC link application, monster book parsing
- **Known blockers:** Adventures pipeline not yet implemented; monster book linking not yet wired up

## Documents in This Directory

| File | Description |
|------|-------------|
| [index.md](index.md) | This file -- overview, quick reference, structure |
| [project.md](project.md) | Domain context, glossary, feature inventory |
| [architecture.md](architecture.md) | Pipeline stages, components, data flow |
| [development.md](development.md) | Setup, prerequisites, workflows |
| [integration.md](integration.md) | Upstream/downstream repos, data contracts |
| [conventions.md](conventions.md) | Naming, commit style, code patterns |
| [troubleshooting.md](troubleshooting.md) | Known issues, common errors |
| [decisions/](decisions/) | Architectural decision records |
