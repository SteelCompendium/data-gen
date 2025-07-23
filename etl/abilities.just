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

_gen_metadata md_fpath:
    #!/usr/bin/env python3
    import re, sys, pathlib
    import yaml

    path = pathlib.Path('{{md_fpath}}')
    text = path.read_text(encoding="utf-8")

    # Split frontmatter & body
    m = re.match(r'^---\s*\n(.*?)\n---\s*\n?(.*)$', text, flags=re.S)
    if m:
        fm_text, body = m.group(1), m.group(2)
        data = yaml.safe_load(fm_text) or {}
    else:
        data, body = {}, text

    # cost and sub-values + type
    assumed_type = 'feature'
    m = re.match(r'^(.*?)\s*\((.*?)\)\s*$', data['header_name'])
    if m:
        data["cost"] = m.group(2)
        m = re.match(r'^([0-9+]+)\s+(.+)$', data["cost"].strip())
        if m:
            data["cost_amount"], data["cost_resource"] = int(m.group(1)), m.group(2)
            assumed_type = 'ability'

    # level
    match = re.search(r'(\d+)(?:st|nd|rd|th)-level-features', data['header_path'])
    if match:
        data['level'] = int(match.group(1))

    # class
    data['class'] = data['header_path'].split('/')[0].title()

    # TODO - I might generate this ahead of time in the config?
    # type
    data['type'] = data.get('type') or assumed_type

    # remove unneeded metadata
    del data['header_path']
    del data['xpath']

    # Reassemble
    new_fm = yaml.safe_dump(data, sort_keys=False).rstrip()
    new_text = f"---\n{new_fm}\n---\n{body}"
    path.write_text(new_text, encoding="utf-8")
