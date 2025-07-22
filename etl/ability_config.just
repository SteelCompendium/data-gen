# Justfile module expected to be named "ability_config"

# Workflow
# # Extract the full ToC from the (corrected) source doc
# just -f markdown.just extract_toc "../../Rules/Draw Steel Heroes.md" "../../Rules/toc.md"
#
# # Convert toc.md to abilities.yml config
# just -f ability_config.just generate_config ../Rules/toc.md ../Rules/abilities.yml

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
    just -f "{{source_file()}}" build_ability_config "{{headers_fpath}}" "{{ability_yml_fpath}}"
    just -f "{{source_file()}}" expand_config_metadata "{{ability_yml_fpath}}"

##################################################
# Private Recipes
##################################################

# Given an input file of headers, will convert them to abilities.yml format for extraction
# IMPORTANT: abilities (H8s) assume that they each have a "useless" header before them which are ignored. This
#   may be a problem if there are abilities under features.  If that is the case, I think I will need this code
#   to ignore H8 as leaves (so that whatever header they are under gets treated as a leaf), but still include them
build_ability_config headers_fpath ability_yml_fpath source="heroes":
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

        return {'source': '{{source}}', 'abilities': output_abilities}

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

        # Cost sub values
        cost_amount, cost_resource = "", ""
        if cost:
            m = re.match(r'^([0-9+]+)\s+(.+)$', cost.strip())
            if m:
                cost_amount, cost_resource = m.group(1), m.group(2)

        # build taxonomy
        taxonomy = header_path
        if cost:
            cost_slug = re.sub(r'[^a-z0-9]+', '-', cost.lower()).strip('-')
            print(cost_slug)
            path_parts = header_path.split('/')
            # remove trailing "-<cost_slug>" if present
            path_parts[-1] = re.sub(rf'-{re.escape(cost_slug)}$', '', path_parts[-1])
            taxonomy = '/'.join(path_parts)

        new_ability = {
            'header_path': header_path,
            'full_header_name': full_header_name,
            'name': header_name,
            'cost': cost,
            'cost_amount': cost_amount,
            'cost_resource': cost_resource,
            'file_dpath': file_dpath,
            'header_id': parts[-1],
            'xpath': xpath,
            'class': parts[0],
            'taxonomy': taxonomy
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
