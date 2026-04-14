# Architecture

## System Overview

data-gen is a multi-stage ETL pipeline orchestrated by `just` (a command runner). Each stage transforms the source material closer to the final structured output.

```
                         ┌──────────────┐
                         │  PDF Source   │
                         └──────┬───────┘
                                │ (manual, pdf_to_md/)
                                v
                    ┌───────────────────────┐
                    │  Markdown Source Docs  │
                    │  (input/heroes/*.md)   │
                    │  (input/monsters/*.md) │
                    └───────────┬───────────┘
                                │
              ┌─────────────────┼─────────────────┐
              v                 v                  v
        ┌──────────┐    ┌────────────┐    ┌──────────────┐
        │  Heroes  │    │  Monsters  │    │  Adventures  │
        │ Pipeline │    │  Pipeline  │    │  (stub)      │
        └────┬─────┘    └─────┬──────┘    └──────┬───────┘
             │                │                   │
             v                v                   v
     ┌──────────────────────────────────────────────────┐
     │              Output data-* repos                 │
     │  data-rules-md, data-rules-json, data-rules-yaml │
     │  data-bestiary-md, data-bestiary-json, ...       │
     │  data-rules-md-dse, data-bestiary-md-dse, ...    │
     │  data-rules-md-linked, data-md-linked, ...       │
     └──────────────────────┬───────────────────────────┘
                            │
                            v
                    ┌───────────────┐
                    │   Unification │
                    │  (data-md,    │
                    │   data-md-dse)│
                    └───────────────┘
```

## Pipeline Stages (Heroes)

The heroes pipeline is the most complete. Each stage produces output in a numbered subdirectory under `staging/heroes/`:

| Stage | Directory | What happens |
|-------|-----------|--------------|
| 0 | `0_features/` | Extract table of contents from source markdown; generate `features.yml` config |
| 1 | `1_html/` | Convert source markdown to HTML via pandoc |
| 2 | `2_html_sections/` | Extract individual sections from HTML using XPath (driven by YAML configs) |
| 3 | `3_md_sections/` | Convert HTML sections back to markdown via pandoc with Lua filters |
| -- | (metadata) | Generate SCC/SCDC classification, frontmatter, and indexes |
| 7 | `7_preformatted/` | Assemble all markdown sections; clean up original source doc |
| 8 | `8_formatted_md/` | Lint/format all markdown with mdformat |
| 9 | `9_linking_md/` | Split into linked (SCC links applied) and unlinked variants |
| 10 | `10_conversions/` | Convert markdown to JSON, YAML; generate DSE markdown; build aggregates |

## Components

| Component | Location | Responsibility | Depends on |
|-----------|----------|---------------|------------|
| **Main justfile** | `etl/justfile` | Entry point, shared constants, utility recipes | All modules |
| **heroes.just** | `etl/heroes.just` | Orchestrates full heroes pipeline | markdown, html, heroes_sections, features, frontmatter, sc_classification, linker, index |
| **monsters.just** | `etl/monsters.just` | Orchestrates full monsters pipeline | markdown, html, monsters_sections, statblocks, featureblocks, frontmatter, sc_classification |
| **unified.just** | `etl/unified.just` | Merges per-book repos into unified `data-md` | Output from heroes + monsters + adventures |
| **adventures.just** | `etl/adventures.just` | Placeholder for adventures pipeline | -- |
| **markdown.just** | `etl/markdown.just` | MD-to-HTML, TOC extraction, linting, blockquote separation, YAML embedding | pandoc, mdformat |
| **html.just** | `etl/html.just` | HTML-to-MD conversion with Lua filter | pandoc |
| **features.just** | `etl/features.just` | Feature metadata generation, conversion to JSON/YAML, DSE embedding, indexes | sc-convert (npm) |
| **statblocks.just** | `etl/statblocks.just` | Statblock MD-to-JSON/YAML conversion | sc-convert (npm) |
| **featureblocks.just** | `etl/featureblocks.just` | Featureblock conversion (malice, dynamic terrain) | sc-convert (npm) |
| **sc_classification.just** | `etl/sc_classification.just` | SCC/SCDC classification assignment (Python) | frontmatter in MD files |
| **frontmatter.just** | `etl/frontmatter.just` | Frontmatter processing: cleanup, sorting (Python) | PyYAML |
| **linker.just** | `etl/linker.just` | Apply/remove SCC cross-reference links (Python) | scc_to_path.json |
| **index.just** | `etl/index.just` | Generate markdown index tables from directory contents | yq |
| **aggregate.just** | `etl/aggregate.just` | Build single-file aggregates of all features/statblocks | -- |
| **section_config.just** | `etl/section_config.just` | Expand section config YAMLs with XPath data | -- |
| **extract_html_sections.just** | `etl/extract_html_sections.just` | Extract HTML sections using XPath | -- |
| **heroes_sections.just** | `etl/heroes_sections.just` | Heroes-specific section extraction config | section_config, extract_html_sections |
| **monsters_sections.just** | `etl/monsters_sections.just` | Monsters-specific section extraction | section_config, extract_html_sections |
| **heroes_frontmatter.just** | `etl/heroes_frontmatter.just` | Heroes-specific frontmatter enrichment | -- |
| **monsters_frontmatter.just** | `etl/monsters_frontmatter.just` | Monsters-specific frontmatter enrichment | -- |
| **features_config.just** | `etl/features_config.just` | Generate features.yml from TOC | -- |
| **link_md/** | `etl/link_md/` | Obsidian-style auto-linker (legacy, Python) | inflect |
| **pre_automation_tools/** | `etl/pre_automation_tools/` | Legacy one-time preprocessing scripts | -- |
| **pdf_to_md/** | `pdf_to_md/` | PDF-to-markdown conversion | marker, OpenAI API |

## Data Flow

Primary input-to-output path (heroes):

1. **Input**: `input/heroes/Draw Steel Heroes.md` (cleaned markdown of the full Heroes book)
2. **Config**: `input/heroes/*.yml` (YAML files defining how to extract each section)
3. **HTML conversion**: Pandoc converts the source markdown to a single HTML file
4. **Section extraction**: XPath queries (derived from YAML configs) extract individual sections as HTML files
5. **MD conversion**: Pandoc converts each HTML section back to markdown (with Lua filters to fix links)
6. **Metadata**: Python scripts assign SCC classifications, generate frontmatter, create index files
7. **Formatting**: mdformat lints all markdown; blockquotes are separated
8. **Linking**: SCC-based cross-references are applied (linked variant) or stripped (unlinked variant)
9. **Conversion**: `sc-convert` transforms markdown to JSON and YAML; YAML is embedded for DSE variant
10. **Output**: Results are copied to sibling `data-*` repos

## Key Design Decisions

| Decision | Rationale |
|----------|-----------|
| Markdown-first pipeline | Source material is authored in markdown; preserving it as the canonical intermediate format keeps the pipeline inspectable |
| Round-trip MD -> HTML -> MD | XPath section extraction is much easier on HTML than markdown; the HTML intermediate is a pragmatic choice |
| Per-section files | Each ability, class, ancestry, etc. gets its own file for granular access and independent versioning |
| Multiple output variants | Different consumers need different formats: plain MD for the website, JSON/YAML for APIs, DSE for web components, linked/unlinked for different rendering contexts |
| `just` as orchestrator | Declarative recipe dependencies, file-level modularity, and embedded Python/Bash scripts in a single toolchain |
| SCC classification system | A universal, hierarchical identifier that works across all content types and supports both human-readable (string) and machine-efficient (decimal) forms |

## Dependencies

| Dependency | Version | Why |
|------------|---------|-----|
| bash | latest (via devbox) | Script execution |
| python | latest (via devbox) | Frontmatter processing, classification, linking |
| just | latest (via devbox) | Task runner / pipeline orchestration |
| jq | latest (via devbox) | JSON processing |
| pandoc | latest (via devbox) | Markdown/HTML conversion |
| html-tidy | latest (via devbox) | HTML cleanup |
| rsync | latest (via devbox) | Directory synchronization (unified pipeline) |
| yq-go | latest (via devbox) | YAML/frontmatter extraction |
| iconv | latest (via devbox) | Character encoding normalization |
| go | latest (via devbox) | Required for go-based tools |
| perl | via devbox | Text processing in some ETL steps |
| figlet | latest (via devbox) | Decorative section headers in pipeline output |
| nodejs | latest (via devbox) | Required for `steel-compendium-sdk` / `sc-convert` CLI |
| python-frontmatter | pip | Frontmatter parsing/writing |
| PyYAML | pip | YAML processing |
| mdformat + plugins | pip | Markdown formatting |
| lxml | pip | XML/HTML processing |
| inflect | pip | Singular/plural form generation (auto-linker) |
| rapidfuzz | pip | Fuzzy matching |
| python-slugify | pip | Slug generation |
| steel-compendium-sdk | npm | `sc-convert` CLI for feature/statblock conversion |

## Extension Points

- **New book**: Add a new `<book>.just` module alongside `heroes.just` and `monsters.just`. Wire it into the main `justfile`'s `gen` recipe and `unified.just`.
- **New section type**: Add a new YAML config in `input/<book>/` and register it in the relevant `*_sections.just` module.
- **New output format**: Add conversion recipes in the relevant pipeline module, using `sc-convert` or custom scripts.
- **New frontmatter fields**: Extend `*_frontmatter.just` modules with additional metadata generation.

## Constraints

- The pipeline must run inside a devbox shell (or equivalent environment with all dependencies).
- The `staging/` directory is ephemeral and wiped at the start of each `gen` run.
- Output repos (`data-*`) must exist as sibling directories in the workspace.
- The `sc-convert` CLI must be installed via npm within the devbox environment.
