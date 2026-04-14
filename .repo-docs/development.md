# Development

## Prerequisites

| Tool | Version | How to get |
|------|---------|-----------|
| devbox | any recent | [jetify.com/devbox](https://www.jetify.com/devbox) |
| git | any recent | System package manager |

All other dependencies (bash, python, just, pandoc, node, etc.) are installed automatically by devbox.

## Setup

1. Clone the repo and its sibling data repos:
   ```bash
   # From the workspace root (steel_compendium/workspace/)
   just clone-all
   ```

2. Enter the devbox environment:
   ```bash
   cd data-gen/etl
   devbox shell
   ```
   This installs all system packages, creates a Python venv, installs pip packages, installs `steel-compendium-sdk` via npm, and installs Go tools.

3. Ensure source documents exist:
   - `input/heroes/Draw Steel Heroes.md` -- the cleaned-up Heroes book markdown
   - `input/monsters/Draw Steel Monsters.md` -- the cleaned-up Monsters book markdown
   - `input/heroes/*.yml` -- section config files (already committed)

4. Run the full pipeline:
   ```bash
   devbox run gen
   # or directly:
   just gen
   ```

## Required Environment Variables

| Variable | Required by | Description |
|----------|------------|-------------|
| `OPEN_AI_KEY` | `pdf_to_md/` only | OpenAI API key for LLM-assisted PDF conversion |

The main ETL pipeline (`etl/`) does not require any environment variables.

## Common Workflows

### Generate all output

```bash
cd etl && devbox shell
just gen
```

This runs: wipe staging -> heroes pipeline -> monsters pipeline -> adventures (stub) -> unify.

### Generate heroes only

```bash
just gen_heroes
```

### Generate monsters only

```bash
just gen_monsters
```

### Convert a PDF to markdown

```bash
cd pdf_to_md && devbox shell
# Requires OPEN_AI_KEY env var
just convert_heroes "Draw Steel Heroes.pdf"
just convert_monsters "Draw_Steel_Monsters_v1.pdf"
```

### Switch all data repos to a branch

```bash
just switch_repos_to develop
```

### Push generated data to repos

After `just gen`, the output is already copied to the sibling `data-*` repos. Commit and push each one manually:

```bash
cd ../data-rules-md && git add -A && git commit -m "Update from data-gen" && git push
# Repeat for each data-* repo
```

### Convert a single feature/statblock

```bash
# Feature markdown to JSON
just features convert "path/to/feature.md" json

# Statblock markdown to YAML
just statblocks convert "path/to/statblock.md" yaml
```

### Lint markdown files

```bash
just markdown lint "path/to/directory"
```

## Testing

There is no automated test suite. Validation is manual:

1. Run `just gen` and inspect the `staging/` directory for intermediate output.
2. Check the `data-*` repos for final output.
3. Verify the compendium website renders correctly after updating.

## Debugging

### Pipeline output

Each stage writes to a numbered subdirectory in `staging/`. To inspect a specific stage:

```bash
ls staging/heroes/
# 0_features/  1_html/  2_html_sections/  3_md_sections/  7_preformatted/  8_formatted_md/  9_linking_md/  10_conversions/
```

### Verbose just output

`just` recipes use `set -euo pipefail` and print section headers. Check stderr for progress messages.

### Frontmatter inspection

```bash
yq e --front-matter=markdown '.' path/to/file.md
```

### Classification state

The SCC classification tree state is stored in `input/classification.json`. Inspect it to understand current type/source assignments.
