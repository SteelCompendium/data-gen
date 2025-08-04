# Justfile module expected to be named "section_config"

#global:
#  source: heroes
#  type: section
#sections:
## sluggified path of headers
#- header_path: introduction/1st-level-features/this-is-an-h8-header-8-energy
## basename of sluggified path
#  item_id: this-is-an-h8-header-8-energy
## File name (header without parens)
#  item_name: This is an H8 Header
## destination directory (unsluggified header path)
#  file_dpath: Introduction/1st-Level Features
## xpath query location
#  xpath: //section[@id='introduction']//section[@id='st-level-features']//section[@id='this-is-an-h8-header-8-energy']

##################################################
# Constants and env vars
##################################################

##################################################
# Public Recipes
##################################################

export BASH_ENV := ".utils/.utilsrc"
set shell := ["bash", "-c"]

# expands a section config file from simply header_path and header_name to full config
# This is intentionally a separate step in case there needs to be some adjustment to the config before expansion
[private]
expand_general config_fpath:
    #!/usr/bin/env python3
    import re
    import yaml
    import sys

    # when resolving a value: declared_field > global_field > generated_field
    def resolve(field_name, default_val, section, global_data):
        if section.get(field_name) is not None:
            return section[field_name]
        if global_data.get(field_name) is not None:
            return global_data[field_name]
        return default_val

    def xpath_literal(s: str) -> str:
        """
        Return an XPath string literal for s, escaping quotes as needed.
        """
        if "'" not in s:
            return f"'{s}'"
        if '"' not in s:
            return f'"{s}"'
        # Need concat('a',"'",'b',...)
        parts = []
        for chunk in s.split("'"):
            if chunk:
                parts.append(f"'{chunk}'")
            parts.append('"\'"')  # a literal single quote
        if parts and parts[-1] == '"\'"':
            parts.pop()  # remove trailing quote literal if s ended with '
        return "concat(" + ", ".join(parts) + ")"

    # expects: header_path
    def expand_section_metadata(section, global_data):
        header_path = section.get('header_path')
        if not header_path:
            print(f"Error: missing header_path: {section}", file=sys.stderr)
            sys.exit(1)

        print(f"    Expanding section config: {header_path}", file=sys.stderr)

        parts = header_path.split('/')

        # Build file path (`s/-/ /g`, fix `1St` capitalization, title case)
        file_path_components = [
            re.sub(
                r'(\d+)(St|Nd|Rd|Th)\s',
                lambda m: m.group(1) + m.group(2).lower() + '-',
                p.replace('-', ' ').title()
            )
            for p in parts[:-1]
        ]
        file_dpath = "/".join(file_path_components)

        # Generate xpath from header path
        xpath_predicates = []
        for part in parts:
            # Base id after stripping leading digits (e.g., '4th-level...' -> 'th-level...')
            base_id = re.sub(r'^\d+', '', part)
            base_id_lit = xpath_literal(base_id)

            # Ordinal detection at segment start (e.g., '4th-level...' -> '4th')
            m = re.match(r'^(\d+)(st|nd|rd|th)\b', part, flags=re.IGNORECASE)
            ordinal = (m.group(1) + m.group(2).lower()) if m else None
            ordinal_lit = xpath_literal(ordinal) if ordinal else None

            # Core id predicate:
            #   @id='{base}' OR (starts-with(@id,'{base}-') AND suffix is digits only)
            pred = (
                f"section[@id={base_id_lit} or "
                f"(starts-with(@id, concat({base_id_lit}, '-')) and "
                f"not(translate(substring-after(@id, concat({base_id_lit}, '-')), '0123456789', '')))]"
            )

            # If the segment had an ordinal, *also* require a descendant header containing that ordinal,
            # to avoid over-matching generic ids like 'th-level-domain-feature'
            if ordinal_lit:
                header_check = (
                    "[.//*[self::h1 or self::h2 or self::h3 or self::h4 or self::h5 or self::h6 or self::p]"
                    f"[contains(normalize-space(.), {ordinal_lit})]]"
                )
                pred = pred + header_check

            xpath_predicates.append(pred)

        xpath = "//" + "//".join(xpath_predicates)

        new_section = {
            **global_data,
            **section,
            'file_dpath': resolve('file_dpath', file_dpath, section, global_data),
            'xpath': resolve('xpath', xpath, section, global_data),
            'item_name': resolve('item_name', None, section, global_data),
            'item_id': resolve('item_id', None, section, global_data),
            'type': resolve('type', None, section, global_data),
            'source': resolve('source', 'unknown_source', section, global_data),
        }
        return new_section

    try:
        with open("{{config_fpath}}", 'r') as f:
            data = yaml.safe_load(f) or {}
    except FileNotFoundError:
        print(f"Error: Input file not found at '{{config_fpath}}'", file=sys.stderr)
        sys.exit(1)

    global_data = data.get('global', {}) or {}

    if 'sections' in data and isinstance(data['sections'], list):
        data['sections'] = [expand_section_metadata(section, global_data) for section in data['sections']]

    with open("{{config_fpath}}", 'w') as f:
        yaml.dump(data, f, sort_keys=False, default_flow_style=False, indent=2)

    print(f"Successfully expanded metadata in '{{config_fpath}}'")
