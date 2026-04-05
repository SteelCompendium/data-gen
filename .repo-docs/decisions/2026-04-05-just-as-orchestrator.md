---
status: accepted
date: 2026-04-05
---

# Just as pipeline orchestrator

## Context

The ETL pipeline involves dozens of interdependent steps across multiple tools (pandoc, Python scripts, shell utilities, npm CLIs). A task runner is needed to orchestrate these steps.

## Options Considered

### Option A: Makefile
- Pros: Universal, well-known, file-based dependency tracking
- Cons: Arcane syntax, poor string handling, hard to embed multi-line scripts

### Option B: Shell scripts
- Pros: No extra tool needed
- Cons: No dependency management, poor modularity, hard to compose

### Option C: Just
- Pros: Clean syntax, module system (`mod`), inline Python/Bash scripts, parameter passing, built-in functions (`titlecase`, `file_stem`)
- Cons: Less common than Make, no file-based dependency tracking

### Option D: Python/Invoke
- Pros: Full programming language, good for complex logic
- Cons: Overhead for simple shell commands, requires Python environment for orchestration layer

## Decision

Option C: Just. The module system enables splitting the pipeline into focused, composable files. Inline multi-line scripts (both Bash and Python) keep logic close to where it's used. The clean syntax reduces boilerplate compared to Make.

## Consequences

- Each pipeline component is a `.just` module imported into the main justfile
- Python logic is embedded directly in justfile recipes rather than standalone scripts
- No file-based dependency tracking -- the pipeline always runs all stages
- `devbox` provides the `just` binary

## Outcome

The modular justfile structure has scaled well to 25+ modules. Embedding Python scripts in recipes works but can make individual recipes long. The lack of file-based dependency tracking means every run is a full rebuild, which takes a few minutes but is acceptable for the current scale.
