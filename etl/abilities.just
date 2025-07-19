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

# TODO - wire this in somewhere
# Given a fully expanded abilities.yml doc, extract all the abilities (and features)
extract_sections ability_fpath html_fpath output_dpath:
    #!/usr/bin/env bash
    set -euo pipefail

    # Requires yq: https://github.com/mikefarah/yq
    if ! command -v yq &> /dev/null; then
        echo "yq could not be found, please install it to proceed." >&2
        exit 1
    fi

    ability_fpath="{{ability_fpath}}"
    html_fpath="{{html_fpath}}"
    output_dpath="{{output_dpath}}"

    # Use yq to output file_dpath, xpath, and header_path as tab-separated values for safe parsing
    yq eval '.abilities[] | [.file_dpath, .xpath, .header_path, .class, .type, .level] | @tsv' "$ability_fpath" | \
        while IFS=$'\t' read -r file_dpath xpath header_path class type level; do
        if [ -z "$file_dpath" ] || [ -z "$xpath" ]; then
            echo "Warning: Skipping ability with missing 'file_dpath' or 'xpath': $header_path" >&2
            continue
        fi

        # make the destination path
        ability_output_dpath="${output_dpath}/${file_dpath}"
        mkdir -p "$ability_output_dpath"

        tmp=$(mktemp -d)

        # Extract features and abilities
        just extract_html_sections extract_section "$tmp" "$xpath" "$html_fpath" "false"

        # Prepend a comment with frontmatter.  Pandoc will pick this up and inject into markdown files
        for file in "$tmp"/*; do
            echo "adding frontmatter to $file"
            {
                echo "<head>"
                echo "  <meta name='class' content='$class' />"
                echo "  <meta name='type' content='$type' />"
                echo "  <meta name='level' content='$level' />"
                echo "</head>"
                cat "$file"
            } > "${ability_output_dpath}/$(basename "$file")"
        done

        rm -rf "$tmp"
    done

    echo "Successfully extracted sections to '$output_dpath'"
    echo "See failed extractions in staging/failed_extractions.txt"


##################################################
# Private Recipes
##################################################

# Given an input file of headers, will convert them to abilities.yml format for extraction
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
                output_abilities.append({'header_path': header_path})

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

        new_ability = {
            'header_path': header_path,
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

        new_ability['type'] = 'ability' if parts[-1].endswith('-1') else 'feature'

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
