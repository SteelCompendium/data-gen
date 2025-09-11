# Justfile module expected to be named "features_config"

# Workflow
# # Extract the full ToC from the (corrected) source doc
# just -f markdown.just extract_toc "../../input/heroes/Draw Steel Heroes.md" "../../input/heroes/toc.md"
#
# # Convert toc.md to features.yml config
# just -f feature_config.just generate_config ../input/heroes/toc.md ../input/heroes/features.yml

##################################################
# Constants and env vars
##################################################

##################################################
# Public Recipes
##################################################

# First convert the headers toc doc to features
# just -f features.just generate_config ../input/heroes/toc.md ../input/heroes/features.yml
# Then extract sections (see just -f features.just extract_sections)
#
# This job is kinda expected to be run once (after the rules.md is done) and then the features.yml is used from then on
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
# ######### My Life for Yours (actual features at h8)
#
# output:
# features:
# - header_path: censor/1st-level-features/censor-order
# - header_path: censor/1st-level-features/deity-and-domains
# - header_path: censor/1st-level-features/wrath-in-combat
# - header_path: censor/1st-level-features/wrath-outside-of-combat
# - header_path: censor/1st-level-features/judgment-1
# - header_path: censor/1st-level-features/judgment-order-benefit
# - header_path: censor/1st-level-features/kit
# - header_path: censor/1st-level-features/my-life-for-yours-1
generate_config headers_fpath feature_yml_fpath:
    #!/usr/bin/env bash
    set -euo pipefail
    just -f "{{source_file()}}" build_feature_config "{{headers_fpath}}" "{{feature_yml_fpath}}"
    just section_config expand_general "{{feature_yml_fpath}}"

##################################################
# Private Recipes
##################################################

# Given an input file of headers, will convert them to features.yml format for extraction
# TODO - check to see if this is still relevant after v1 sdk
# IMPORTANT: features (H8s) assume that they each have a "useless" header before them which are ignored. This
#   may be a problem if there are abilities under features.  If that is the case, I think I will need this code
#   to ignore H8 as leaves (so that whatever header they are under gets treated as a leaf), but still include them
# TODO - this source needs to move
build_feature_config headers_fpath feature_yml_fpath source="mcdm.heroes.v1":
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
        Parses the document content and extracts feature paths.
        """
        rejectList = []

        # These are all sub-items of Null's 7th-level Psi boost trait
        rejectList.append("Dynamic Power (1 Discipline)")
        rejectList.append("Expanded Power (3 Discipline)")
        rejectList.append("Extended Power (1 Discipline)")
        rejectList.append("Heightened Power (1 Discipline)")
        rejectList.append("Magnified Power (5 Discipline)")
        rejectList.append("Shared Power (5 Discipline)")
        rejectList.append("Sharpened Power (1 Discipline)")
        # These are all sub-items of Talent's 6th-level Psi boost trait
        rejectList.append("Dynamic Power (1 Clarity)")
        rejectList.append("Expanded Power (3 Clarity)")
        rejectList.append("Extended Power (1 Clarity)")
        rejectList.append("Heightened Power (1 Clarity)")
        rejectList.append("Magnified Power (5 Clarity)")
        rejectList.append("Shared Power (5 Clarity)")
        rejectList.append("Sharpened Power (1 Clarity)")

        all_headers = []
        for line in content.splitlines():
            level, text = parse_header(line)
            if level is not None:
                all_headers.append({'level': level, 'text': text})

        path_stack = []
        output_features = []

        for i, header in enumerate(all_headers):
            level = header['level']
            text = header['text']

            if text in rejectList:
                continue

            if text.lower().endswith("table"):
                continue

            while path_stack and path_stack[-1]['level'] >= level:
                path_stack.pop()

            is_leaf = (i == len(all_headers) - 1) or \
                      (all_headers[i+1]['level'] <= level)

            is_under_level_features = False
            level_features_header_text = None
            h1_text = None

            for p_header in path_stack:
                if p_header['level'] == 2:
                    h1_text = p_header['text']
                if '-Level Features' in p_header['text']:
                    is_under_level_features = True
                    level_features_header_text = p_header['text']

            if is_under_level_features and is_leaf:
                feature_name = text
                kebab_feature_name = to_kebab_case(feature_name)

                parent_header_text = path_stack[-1]['text'] if path_stack else ""
                if feature_name == parent_header_text:
                    kebab_feature_name += "-1"

                path_parts = []
                if h1_text:
                    path_parts.append(to_kebab_case(h1_text))
                if level_features_header_text:
                    path_parts.append(to_kebab_case(level_features_header_text))
                path_parts.append(kebab_feature_name)

                header_path = "/".join(path_parts)

                # TODO - I dont think this works...
                # TODO - idk if I like this here, but `type` needs to be in metadata before classification
                # type is generated here because its needed for classification
                base_type = 'ability' if level == 8 else 'trait'
                # base_type = 'trait'
                # m = re.match(r'^(.*?)\s*\(([0-9+]+)\s+(.+)\)\s*$', feature_name)
                # if m:
                #     base_type = 'ability'
                clazz = header_path.split('/')[0]
                match = re.search(r'((\d+)(?:st|nd|rd|th)-level-feature)s', header_path)
                if match:
                    level_feature = match.group(1)
                type = '/'.join(['feature', base_type, clazz, level_feature])

                # Note: any metadata added here needs to get added to extract_html_sections too
                output_features.append({
                    'header_path': header_path,
                    'item_name': feature_name,
                    'item_id': to_kebab_case(feature_name),
                    'type': type,
                    'feature_type': base_type
                })

            path_stack.append(header)

        return {'global': {'source': '{{source}}'}, 'sections': output_features}

    try:
        with open("{{headers_fpath}}", 'r') as f:
            content = f.read()
    except FileNotFoundError:
        print(f"Error: Input file not found at '{{headers_fpath}}'")
        exit

    data = process_document(content)

    with open("{{feature_yml_fpath}}", 'w') as f:
        yaml.dump(data, f, sort_keys=False)

    print(f"Successfully created '{{feature_yml_fpath}}'")
