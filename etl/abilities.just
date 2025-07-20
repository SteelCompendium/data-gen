# Justfile module expected to be named "abilities"

# Workflow
# # Extract the full ToC from the (corrected) source doc
# just -f markdown.just extract_toc "../../Rules/Draw Steel Heroes.md" "../../Rules/toc.md"
#
# # Convert toc.md to abilities.yml config
# just -f abilities.just  generate_config ../Rules/toc.md ../Rules/abilities.yml
#
# # Extract ability html from single html file (note, the html file needs to be generated. Run in devbox
# devbox shell
# just -f abilities.just extract_sections "../Rules/abilities.yml" "../staging/heroes/1_html/Draw Steel Heroes.html" "../staging/heroes/2_html_sections/Abilities"

##################################################
# Constants and env vars
##################################################

##################################################
# Public Recipes
##################################################

# First convert the headers toc doc to abilities
# just -f abilities.just generate_config ../Rules/toc.md ../Rules/abilities.yml
# Then extract sections (see just -f abilities.just extract_sections)
#
# This job is kinda expected to be run once (after the rules.md is done) and then the abilities.yml is used from then on
#
# headers_fpath expectation:
# # Censor
# ##### Basics
# ##### 1st-Level Features
# ###### Censor Order
# ###### Deity and Domains
# ###### Wrath
# ####### Wrath in Combat
# ####### Wrath Outside of Combat
# ###### Judgment
# ######### Judgment
# ####### Judgment Order Benefit
# ###### Kit
# ###### My Life for Yours
# ######### My Life for Yours (actual abilities at h8)
#
# output:
# abilities:
# - header_path: censor/1st-level-features/censor-order
# - header_path: censor/1st-level-features/deity-and-domains
# - header_path: censor/1st-level-features/wrath-in-combat
# - header_path: censor/1st-level-features/wrath-outside-of-combat
# - header_path: censor/1st-level-features/judgment-1
# - header_path: censor/1st-level-features/judgment-order-benefit
# - header_path: censor/1st-level-features/kit
# - header_path: censor/1st-level-features/my-life-for-yours-1
generate_config headers_fpath ability_yml_fpath:
    #!/usr/bin/env bash
    set -euo pipefail
    just -f "{{source_file()}}" convert "{{headers_fpath}}" "{{ability_yml_fpath}}"
    just -f "{{source_file()}}" expand_config_metadata "{{ability_yml_fpath}}"

# Given a fully expanded abilities.yml doc, extract all the abilities (and features)
extract_sections ability_fpath html_fpath output_dpath:
    #!/usr/bin/env bash
    set -euo pipefail

    ability_fpath="{{ability_fpath}}"
    html_fpath="{{html_fpath}}"
    output_dpath="{{output_dpath}}"

    # which keys to pull from the YAML
    fields=(file_dpath xpath header_path name cost class type level)
    # which to emit as <meta> (plus 'name' for filename)
    meta_fields=(name cost class type level)

    # Build the comma‑separated selector list, forcing missing keys → ""
    prefixed=()
    for key in "${fields[@]}"; do
        prefixed+=( "(.${key} // \"\")" )
    done
    comma_list="$(IFS=,; echo "${prefixed[*]}")"

    mkdir -p "$output_dpath"

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
        class="${vals[5]:-}"
        type="${vals[6]:-}"
        level="${vals[7]:-}"

        if [[ -z "$file_dpath" || -z "$xpath" ]]; then
            echo "Warning: Skipping ability with missing 'file_dpath' or 'xpath': $header_path" >&2
            continue
        fi

        ability_output_dpath="$output_dpath/$file_dpath"
        mkdir -p "$ability_output_dpath"

        tmpdir="$(mktemp -d)"
        just extract_html_sections extract_section "$tmpdir" "$xpath" "$html_fpath" "false"

        # Apply metadata to html files that will convert to frontmatter
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
                cat "$htmlfile"
            } > "$ability_output_dpath/$filename"
        done

        rm -rf "$tmpdir"
    done
    echo "Successfully extracted sections to '$output_dpath'"
    echo "See failed extractions in staging/failed_extractions.txt"

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

# Given an input file of headers, will convert them to abilities.yml format for extraction
# IMPORTANT: abilities (H8s) assume that they each have a "useless" header before them which are ignored. This
#   may be a problem if there are abilities under features.  If that is the case, I think I will need this code
#   to ignore H8 as leaves (so that whatever header they are under gets treated as a leaf), but still include them
convert headers_fpath ability_yml_fpath:
    #!/usr/bin/env python3

    import argparse
    import re
    import yaml

    def to_kebab_case(text):
        """Converts a string to kebab-case."""
        text = text.replace("'", "")
        text = re.sub(r'([a-z0-9])([A-Z])', r'\1-\2', text)
        text = re.sub(r'[^a-zA-Z0-9]+', '-', text)
        return text.strip('-').lower()

    def parse_header(line):
        """Parses a header line, returning its level and text."""
        if not line.startswith('#'):
            return None, None

        level = 0
        while level < len(line) and line[level] == '#':
            level += 1

        text = line[level:].strip()
        return level, text

    def process_document(content):
        """
        Parses the document content and extracts ability paths.
        """
        all_headers = []
        for line in content.splitlines():
            level, text = parse_header(line)
            if level is not None:
                all_headers.append({'level': level, 'text': text})

        path_stack = []
        output_abilities = []

        for i, header in enumerate(all_headers):
            level = header['level']
            text = header['text']

            while path_stack and path_stack[-1]['level'] >= level:
                path_stack.pop()

            is_leaf = (i == len(all_headers) - 1) or \
                      (all_headers[i+1]['level'] <= level)

            is_under_level_features = False
            level_features_header_text = None
            h1_text = None

            for p_header in path_stack:
                if p_header['level'] == 1:
                    h1_text = p_header['text']
                if '-Level Features' in p_header['text']:
                    is_under_level_features = True
                    level_features_header_text = p_header['text']

            if is_under_level_features and is_leaf:
                ability_name = text
                kebab_ability_name = to_kebab_case(ability_name)

                parent_header_text = path_stack[-1]['text'] if path_stack else ""
                if ability_name == parent_header_text:
                    kebab_ability_name += "-1"

                path_parts = []
                if h1_text:
                    path_parts.append(to_kebab_case(h1_text))
                if level_features_header_text:
                    path_parts.append(to_kebab_case(level_features_header_text))
                path_parts.append(kebab_ability_name)

                header_path = "/".join(path_parts)
                output_abilities.append({'header_path': header_path, 'full_header_name': ability_name})

            path_stack.append(header)

        return {'abilities': output_abilities}

    try:
        with open("{{headers_fpath}}", 'r') as f:
            content = f.read()
    except FileNotFoundError:
        print(f"Error: Input file not found at '{{headers_fpath}}'")
        exit

    data = process_document(content)

    with open("{{ability_yml_fpath}}", 'w') as f:
        yaml.dump(data, f, sort_keys=False)

    print(f"Successfully created '{{ability_yml_fpath}}'")

# Takes a basic abilities.yml file and populates all the metadata
# This is intentionally a separate step in case there needs to be some adjustment to the config before expansion
expand_config_metadata ability_yml_fpath:
    #!/usr/bin/env python3

    import re
    import yaml
    import sys

    def expand_ability_metadata(ability):
        header_path = ability['header_path']
        parts = header_path.split('/')

        file_path_components = [re.sub(r'(\d+)(St|Nd|Rd|Th)\s', lambda m: m.group(1) + m.group(2).lower()+'-', p.replace('-', ' ').title()) for p in parts[:-1]]
        file_dpath = "/".join(file_path_components)

        xpath_id_parts = [re.sub(r'^\d+', '', part) for part in parts]
        xpath = "//" + "//".join([f"section[@id='{p}']" for p in xpath_id_parts])

        full_header_name = ability['full_header_name']
        # capture header_name and cost
        m = re.match(r'^(.*?)\s*\((.*?)\)\s*$', full_header_name)
        if m:
            header_name, cost = m.group(1), m.group(2)
        else:
            # fallback if it doesn’t match the "foo (8 bar)" form
            header_name, cost = full_header_name, ''

        new_ability = {
            'header_path': header_path,
            'full_header_name': full_header_name,
            'name': header_name,
            'cost': cost,
            'file_dpath': file_dpath,
            'header_id': parts[-1],
            'xpath': xpath,
            'class': parts[0]
        }

        level = None
        for part in parts:
            match = re.search(r'(\d+)(?:st|nd|rd|th)-level-features', part)
            if match:
                level = int(match.group(1))
                break
        if level is not None:
            new_ability['level'] = level

        # Old logic was to assume that all abilities will have a header before it with the exact same name
        #new_ability['type'] = 'ability' if parts[-1].endswith('-1') else 'feature'
        # New logic is to check to see if there is a cost?
        new_ability['type'] = 'ability' if cost else 'feature'

        return new_ability

    try:
        with open("{{ability_yml_fpath}}", 'r') as f:
            data = yaml.safe_load(f)
    except FileNotFoundError:
        print(f"Error: Input file not found at '{{ability_yml_fpath}}'", file=sys.stderr)
        sys.exit(1)

    if 'abilities' in data and isinstance(data['abilities'], list):
        data['abilities'] = [expand_ability_metadata(ability) for ability in data['abilities']]

    with open("{{ability_yml_fpath}}", 'w') as f:
        yaml.dump(data, f, sort_keys=False, default_flow_style=False, indent=2)

    print(f"Successfully expanded metadata in '{{ability_yml_fpath}}'")
