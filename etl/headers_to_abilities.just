#

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
        path_stack = []  # List of (text, level) tuples
        output_abilities = []

        for line in content.splitlines():
            level, text = parse_header(line)
            if level is None:
                continue

            # As per the user's example, abilities are at header level 8.
            is_ability_header = (level == 8)

            # Update path stack based on header level.
            while path_stack and path_stack[-1][1] >= level:
                path_stack.pop()

            parent_header_text = path_stack[-1][0] if path_stack else ""
            path_stack.append((text, level))

            if is_ability_header:
                h1 = next((item[0] for item in path_stack if item[1] == 1), None)
                level_features = next((item[0] for item in path_stack if '-Level Features' in item[0]), None)

                ability_name = text
                kebab_ability_name = to_kebab_case(ability_name)

                if ability_name == parent_header_text:
                    kebab_ability_name += "-1"

                path_parts = []
                if h1:
                    path_parts.append(to_kebab_case(h1))
                if level_features:
                    path_parts.append(to_kebab_case(level_features))
                path_parts.append(kebab_ability_name)

                header_path = "/".join(path_parts)
                output_abilities.append({'header_path': header_path})

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


# Censor
#### Basics
#### 1st-Level Features
##### Censor Order
##### Deity and Domains
##### Wrath
###### Wrath in Combat
###### Wrath Outside of Combat
##### Judgment
######## Judgment
###### Judgment Order Benefit
##### Kit
##### My Life for Yours
######## My Life for Yours
##### 1st-Level Domain Feature
###### Blessing of Compassion
###### Blessing of Comprehension
###### Blessing of Fortunate Weather
#### 2nd-Level Features
##### 2nd-Level Order Features
###### It Was Foretold
###### Judge of Character
###### Lead by Example
###### Saint's Vigilance
###### A Sense for Truth
###### Stalwart Icon
##### 2nd-Level Order Ability
###### 2nd-Level Exorcist Ability
######## It Is Justice You Fear
######## Revelator