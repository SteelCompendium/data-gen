# Justfile module expected to be named "abilities"

# # Extract ability html from single html file (note, the html file needs to be generated. Run in devbox
# devbox shell
# just -f abilities.just extract_sections "../input/heroes/abilities.yml" "../staging/heroes/1_html/Draw Steel Heroes.html" "../staging/heroes/2_html_sections/Abilities"

##################################################
# Constants and env vars
##################################################

##################################################
# Public Recipes
##################################################

# this recipe assumes that there is already section-metadata applied to the frontmatter of the document
# Note: these could be abilities or features (right?)
gen_metadata md_dpath:
    #!/usr/bin/env bash
    set -euo pipefail
    find "{{md_dpath}}" -type f -name '*.md' | while read -r fpath; do
        just abilities _gen_metadata "$fpath"
    done

# Converts ability markdown into another format (yaml, json, etc)
convert_all md_dpath output_format output_dpath:
    #!/usr/bin/env bash
    set -euo pipefail
    echo >&2 "Abilities: converting markdown to '{{output_format}}'"
    mkdir -p "{{output_dpath}}"
    sc-convert \
        --type ability \
        --from markdown \
        --to "{{output_format}}" \
        --output "{{output_dpath}}" \
        "{{md_dpath}}"

# Converts ability markdown into another format (yaml, json, etc) and prints output --prefix
convert md_fpath output_format:
    #!/usr/bin/env bash
    set -euo pipefail
    sc-convert \
        --type ability \
        --from markdown \
        --to "{{output_format}}" \
        "{{md_fpath}}"

# depth=0 means only the dirs in the dpath
# depth=1 means nested children (one-level) are included as well
gen_index_for_each_dir_in dpath depth="0":
    #!/usr/bin/env bash
    set -euo pipefail
    just _print_section "Generating indexes"
    echo >&2 "    Parent dpath:'{{dpath}}'"
    echo >&2

    find "{{dpath}}"/* -maxdepth '{{depth}}' -type d | while read -r to_index; do
        # Skipping kit dirs (Kits/Raider), but still indexing the Kit dir
        if [[ "$to_index" == */Kits/* ]]; then
            continue
        fi

        index_fpath="${to_index}/Index.md"
        # Remove and prefix path, remove leading '/', replace intermediate '/' with ': '
        title="${to_index#{{dpath}}}"
        title="${title#/}"
        title="$(echo "$title" | sed -E 's|/|: |')"
        just index gen "$to_index" "$index_fpath" "file_name cost level feature_type action_type distance target" "$title"
    done

# Generates a single file containing all ability data
gen_aggregate_data_doc data_dpath data_format output_fpath:
    #!/usr/bin/env bash
    set -euo pipefail
    just _print_section "Generating aggregate file for '{{data_format}}' ('{{data_dpath}}')"
    aggregate_fpath=$(mktemp)

    # header
    if [ "{{data_format}}" == "xml" ]; then
        echo "<abilities>" > "$aggregate_fpath"
    elif [ "{{data_format}}" == "json" ]; then
        echo '{ "abilities": [' > "$aggregate_fpath"
    elif [ "{{data_format}}" == "yaml" ]; then
        echo 'abilities: ' > "$aggregate_fpath"
    fi

    # body
    find "{{data_dpath}}" -type f -name '*.{{data_format}}' | while read -r fpath; do
        if [ "{{data_format}}" == "xml" ]; then
            # indent
            sed 's/^/  /' "$fpath" >> "$aggregate_fpath"
        elif [ "{{data_format}}" == "json" ]; then
            # prefix each line with two spaces, and add a comma to the end of the last line
            sed -e 's/^/  /' -e '$ s/$/,/' "$fpath" >> "$aggregate_fpath"
        elif [ "{{data_format}}" == "yaml" ]; then
            # First line gets "  - ", subsequent lines get 4 spaces
            sed -e '1s/^/  - /' -e '1!s/^/    /' "$fpath" >> "$aggregate_fpath"
        fi
    done

    # footer
    if [ "{{data_format}}" == "xml" ]; then
        echo "</abilities>" >> "$aggregate_fpath"
    elif [ "{{data_format}}" == "json" ]; then
        sed -i '${s/,$//}' "$aggregate_fpath"
        echo "]" >> "$aggregate_fpath"
        echo "}" >> "$aggregate_fpath"
    elif [ "{{data_format}}" == "yaml" ]; then
        echo "" >> "$aggregate_fpath"
    fi
    mv "$aggregate_fpath" "{{output_fpath}}"

# TODO - replace this with just markdown embed_yaml
# For each markdown file in md_dpath, the body gets replaced with a DSE codeblock for a statblock
embed_abilities md_dpath yaml_dpath:
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
        new_body = f"```ds-ability\n{yaml_text}```\n"

        # Load & preserve frontmatter; replace only the content/body
        post = frontmatter.load(md_file)
        post.content = new_body

        # Write back
        md_file.write_text(frontmatter.dumps(post), encoding="utf-8")


##################################################
# Private Recipes
##################################################
