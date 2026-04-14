# Conventions

## File and Directory Naming

- **Justfile modules**: `snake_case.just` (e.g., `heroes_sections.just`, `sc_classification.just`)
- **Input YAML configs**: `snake_case.yml` (e.g., `abilities.yml`, `feature_fixes.yml`)
- **Source documents**: Title Case with spaces (e.g., `Draw Steel Heroes.md`, `Draw Steel Monsters.md`)
- **Output directories**: Title Case (e.g., `Features/`, `Abilities/`, `Chapters/`, `Statblocks/`)
- **Generated markdown files**: Title Case with spaces (matching the game content name)
- **Staging directories**: Numbered prefixes for pipeline order (e.g., `0_features/`, `1_html/`, `8_formatted_md/`)

## Code Style

### Justfile recipes

- Module declaration at top: `# Justfile module expected to be named "<name>"`
- Constants section, then public recipes, then private recipes -- each separated by `#` banner comments
- Private recipes prefixed with `_`
- All scripts use `#!/usr/bin/env bash` with `set -euo pipefail`
- Python scripts are embedded directly in justfile recipes using `#!/usr/bin/env python3`
- `BASH_ENV` and shell settings declared per module as needed

### Python (embedded)

- Python scripts are embedded in `.just` files, not standalone `.py` files (exception: `link_md/obs-auto-linker.py`)
- Uses `pathlib.Path` for file operations
- Uses `python-frontmatter` library for markdown frontmatter parsing
- Uses `yaml.safe_load` / `yaml.safe_dump` for YAML processing

### Variable naming (justfile)

- Directory paths: `*_dpath` suffix (e.g., `heroes_staging_dpath`, `input_dpath`)
- File paths: `*_fpath` suffix (e.g., `html_fpath`, `scc_to_path_json_fpath`)
- Log prefixes: `log_prefix` variable for module identification

## Commit Messages

Observed pattern: imperative or present-tense descriptions without conventional commit prefixes.

Examples from history:
- `Corrects Malice ability on Ogre Jug and adds noncombatant`
- `Adds aggregate files for json and yaml`
- `Correcting a lot of issues with type uniqueness`
- `Cleanup from errata`
- `Bugfixes!`

Style: informal, content-focused. Describes what changed in game-data terms rather than code terms.

## Markdown Header Levels

The source documents use extended header levels beyond standard markdown:

| Level | Meaning |
|-------|---------|
| H1-H6 | Standard chapter/section hierarchy |
| H7 (7 `#`) | Statblocks (converted to bold+span in output) |
| H8 (8 `#`) | Abilities/features (converted to bold+span in output) |
| H9 (9 `#`) | Featureblocks: malice, dynamic terrain (converted to bold+span in output) |

## Justfile Module Pattern

Every module follows this structure:

```just
# Justfile module expected to be named "<module_name>"

##################################################
# Constants and env vars
##################################################

# ... module-specific constants

##################################################
# Public Recipes
##################################################

export BASH_ENV := ".utils/.utilsrc"
set shell := ["bash", "-c"]

# public recipes here

##################################################
# Private Recipes
##################################################

# private recipes here (prefixed with _)
```
