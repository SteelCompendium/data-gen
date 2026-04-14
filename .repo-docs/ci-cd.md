# CI/CD

## Pipeline Overview

data-gen has no CI/CD pipeline. The ETL pipeline is run manually on a developer's machine inside a devbox shell. There are no automated builds, tests, or deployments.

## Build Process

All builds are local. The canonical build command:

```bash
cd etl && devbox shell
just gen
```

This runs the full pipeline: wipe staging, heroes pipeline, monsters pipeline, adventures (stub), and unification. Output is copied to sibling `data-*` repos.

### Build Artifacts

| Artifact | Location | Description |
|----------|----------|-------------|
| Staging intermediates | `staging/` (gitignored) | Ephemeral; wiped on each run |
| Final output | Sibling `data-*` repos | Markdown, JSON, YAML, DSE variants |
| Classification state | `input/classification.json` | SCC type/source tree; committed to this repo |

## Branch Strategy

| Branch | Purpose |
|--------|---------|
| `main` | Stable, current output |
| `develop` | Active development |
| `monsters` | Monster book pipeline work |
| `links` | SCC linking feature development |
| Various feature branches | Short-lived, merged to develop or main |

No branch protection rules are configured.

## Release Process

There are no versioned releases or tags. The workflow is:

1. Run `just gen` locally
2. Commit and push changes to each `data-*` output repo manually
3. In the `compendium` project, run `just update` to pull new data commits into the website

### Rollback

Roll back by reverting commits in the affected `data-*` repos and re-running `just update` in the compendium project.

## Environments

| Environment | Description |
|-------------|-------------|
| Local (devbox shell) | Only environment; all pipeline work happens here |

## Secrets and Configuration

| Secret | Used by | Description |
|--------|---------|-------------|
| `OPEN_AI_KEY` | `pdf_to_md/` only | OpenAI API key for LLM-assisted PDF conversion. Not needed for the main ETL pipeline. |
