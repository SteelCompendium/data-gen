# Justfile module expected to be named "statblocks"

# # Extract ability html from single html file (note, the html file needs to be generated. Run in devbox
# devbox shell
# just -f abilities.just extract_sections "../input/heroes/abilities.yml" "../staging/heroes/1_html/Draw Steel Heroes.html" "../staging/heroes/2_html_sections/Abilities"

##################################################
# Constants and env vars
##################################################

##################################################
# Public Recipes
##################################################


# Converts statblock markdown into another format (yaml, json, etc)
convert_all md_dpath output_format output_dpath:
    #!/usr/bin/env bash
    set -euo pipefail
    echo >&2 "Statblocks: converting markdown to '{{output_format}}'"
    sc-convert \
        --type statblock \
        --from markdown \
        --to "{{output_format}}" \
        --output "{{output_dpath}}" \
        "{{md_dpath}}"

# Converts statblock markdown into another format (yaml, json, etc) and prints output
convert md_fpath output_format:
    #!/usr/bin/env bash
    set -euo pipefail
    sc-convert \
        --type statblock \
        --from markdown \
        --to "{{output_format}}" \
        "{{md_fpath}}"

# For each markdown file in md_dpath, the body gets replaced with a DSE codeblock for a statblock
embed_statblocks md_dpath yaml_dpath:
    #!/usr/bin/env python3
    import sys
    from pathlib import Path
    import frontmatter

    md_root = Path('{{md_dpath}}').resolve()
    yaml_root = Path('{{yaml_dpath}}').resolve()

    if not md_root.is_dir():
        print(f"Markdown root not found: {md_root}", file=sys.stderr)
        sys.exit(2)
    if not yaml_root.is_dir():
        print(f"YAML root not found: {yaml_root}", file=sys.stderr)
        sys.exit(3)

    for md_file in md_root.rglob("*.md"):
        rel = md_file.relative_to(md_root)

        # Candidate YAML paths in the mirror dir (same relpath + different extension)
        yaml_candidate_yaml = yaml_root / rel.with_suffix(".yaml")
        yaml_candidate_yml  = yaml_root / rel.with_suffix(".yml")

        yaml_path = None
        if yaml_candidate_yaml.exists():
            yaml_path = yaml_candidate_yaml
        elif yaml_candidate_yml.exists():
            yaml_path = yaml_candidate_yml

        if yaml_path is None:
            continue

        # Read YAML text exactly as-is
        yaml_text = yaml_path.read_text(encoding="utf-8")

        # Build the replacement body as a fenced code block
        # Ensure a trailing newline inside the block for clean formatting
        if not yaml_text.endswith("\n"):
            yaml_text += "\n"
        new_body = f"```ds-statblock\n{yaml_text}```\n"

        # Load & preserve frontmatter; replace only the content/body
        post = frontmatter.load(md_file)
        post.content = new_body

        # Write back
        md_file.write_text(frontmatter.dumps(post), encoding="utf-8")
