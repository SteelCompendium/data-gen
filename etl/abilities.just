# Justfile module expected to be named "abilities"

# # Extract ability html from single html file (note, the html file needs to be generated. Run in devbox
# devbox shell
# just -f abilities.just extract_sections "../Rules/abilities.yml" "../staging/heroes/1_html/Draw Steel Heroes.html" "../staging/heroes/2_html_sections/Abilities"

##################################################
# Constants and env vars
##################################################

##################################################
# Public Recipes
##################################################

# Given a fully expanded abilities.yml doc, extract all the abilities (and features)
extract_sections ability_fpath html_fpath output_dpath:
    #!/usr/bin/env bash
    set -euo pipefail

    ability_fpath="{{ability_fpath}}"
    html_fpath="{{html_fpath}}"
    output_dpath="{{output_dpath}}"

    # which keys to pull from the YAML
    fields=(file_dpath xpath header_path name cost cost_amount cost_resource class type level taxonomy)
    # which to emit as <meta> (plus 'name' for filename)
    meta_fields=(name cost cost_amount cost_resource class type level taxonomy)

    # Build the comma‑separated selector list, forcing missing keys → ""
    prefixed=()
    for key in "${fields[@]}"; do
        prefixed+=( "(.${key} // \"\")" )
    done
    comma_list="$(IFS=,; echo "${prefixed[*]}")"

    mkdir -p "$output_dpath"

    # get the source from the input
    source="$(yq eval ".source" "$ability_fpath")"

    # Use ASCII unit separator (octal 037) to preserve empty TSV columns
    yq eval ".abilities[] | [${comma_list}] | @tsv" "$ability_fpath" \
    | tr '\t' '\037' \
    | while IFS=$'\037' read -r -a vals; do
        # now each empty field becomes an empty string in "${vals[@]}"
        file_dpath="${vals[0]:-}"
        xpath="${vals[1]:-}"
        header_path="${vals[2]:-}"
        name="${vals[3]:-}"
        cost="${vals[4]:-}"
        cost_amount="${vals[5]:-}"
        cost_resource="${vals[6]:-}"
        class="${vals[7]:-}"
        type="${vals[8]:-}"
        level="${vals[9]:-}"
        taxonomy="${vals[10]:-}"

        if [[ -z "$file_dpath" || -z "$xpath" ]]; then
            echo "Warning: Skipping ability with missing 'file_dpath' or 'xpath': $header_path" >&2
            continue
        fi

        ability_output_dpath="$output_dpath/$file_dpath"
        mkdir -p "$ability_output_dpath"

        tmpdir="$(mktemp -d)"
        just extract_html_sections extract_section "$tmpdir" "$xpath" "$html_fpath" "false"

        # Update each html file: Apply metadata (later frontmatter), update header formatting
        for htmlfile in "$tmpdir"/*; do
            filename="$(basename "$htmlfile")"
            # use basename sans extension as the 'name' meta
            name="${filename%.*}"
            {
                echo "<head>"
                for key in "${meta_fields[@]}"; do
                    val="${!key}"
                    if [[ -n "$val" ]]; then
                        printf '  <meta name="%s" content="%s" />\n' "$key" "$val"
                    fi
                done
                echo "</head>"
                just abilities replace_p_heading_with_h6 "$(cat "$htmlfile")"
            } > "$ability_output_dpath/$filename"
        done

        rm -rf "$tmpdir"
    done
    echo "Successfully extracted sections to '$output_dpath'"
    echo "See failed extractions in staging/failed_extractions.txt"

# Converts ability markdown into another format (yaml, json, etc)
convert_all md_dpath output_format output_dpath:
    #!/usr/bin/env bash
    set -euo pipefail
    echo >&2 "Abilities: converting markdown to '{{output_format}}'"
    npx --package steel-compendium-sdk sc-convert \
        --from markdown \
        --to "{{output_format}}" \
        --output "{{output_dpath}}" \
        "{{md_dpath}}"

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
        just index gen "$to_index" "$index_fpath" "file_name cost level type" "$title"
    done

##################################################
# Private Recipes
##################################################

# Given a string, replace any `<p class="heading">...</p>` with an `h6` instead
replace_p_heading_with_h6 html_string:
    #!/usr/bin/env python3
    import re
    html = """
    {{html_string}}
    """
    pattern = re.compile(
        r'<p(?P<attrs>[^>]*)\bclass="heading"(?P<rest>[^>]*)>(?P<inner>.*?)</p>',
        re.DOTALL
    )
    new_html = pattern.sub(r'<h6\g<attrs> class="heading"\g<rest>>\g<inner></h6>', html)
    print(new_html)