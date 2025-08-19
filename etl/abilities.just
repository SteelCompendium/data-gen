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
    npx --package steel-compendium-sdk sc-convert \
        --type ability \
        --from markdown \
        --to "{{output_format}}" \
        --output "{{output_dpath}}" \
        "{{md_dpath}}"

# Converts ability markdown into another format (yaml, json, etc) and prints output
convert md_fpath output_format:
    #!/usr/bin/env bash
    set -euo pipefail
    npx --package steel-compendium-sdk sc-convert \
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
        index_fpath="${to_index}/Index.md"
        # Remove and prefix path, remove leading '/', replace intermediate '/' with ': '
        title="${to_index#{{dpath}}}"
        title="${title#/}"
        title="$(echo "$title" | sed -E 's|/|: |')"
        just index gen "$to_index" "$index_fpath" "file_name cost level feature_type " "$title"
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

##################################################
# Private Recipes
##################################################
