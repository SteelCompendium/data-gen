# Justfile module expected to be named "extract_section_config"

# TODO
# - do I want an id generator???
# - globals should get applied ot the metadata (liek source)

#global:
#  source: heroes
#  type: section
#sections:
## sluggified path of headers
#- header_path: introduction/1st-level-features/this-is-an-h8-header-8-energy
## basename of sluggified path
#  item_id: this-is-an-h8-header-8-energy
## Full header name (with parens)
#  header_name: This is an H8 Header (8 Energy)
## File name (header without parens)
#  name: This is an H8 Header
## destination directory (unsluggified header path)
#  file_dpath: Introduction/1st-Level Features
## xpath query location
#  xpath: //section[@id='introduction']//section[@id='st-level-features']//section[@id='this-is-an-h8-header-8-energy']
## header path without the parens
#  taxonomy: introduction/1st-level-features/this-is-an-h8-header

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

    # expects: header_path, section_name
    def expand_section_metadata(section, global_data):
        header_path = section['header_path']
        section_name = section['section_name']
        if not header_path or not section_name:
            print(f"Error: missing header_path or section_name: {section}", file=sys.stderr)
            sys.exit(1)

        print(f"    Expanding section config: {header_path}", file=sys.stderr)

        parts = header_path.split('/')

        # capture name and parens
        m = re.match(r'^(.*?)\s*\((.*?)\)\s*$', section_name)
        if m:
            name, parens = m.group(1), m.group(2)
        else:
            # fallback if it doesn’t match the "foo (8 bar)" form
            name, parens = section_name, ''

        # Build file path (`s/-/ /g`, fix `1St` capitalization, title case)
        file_path_components = [re.sub(r'(\d+)(St|Nd|Rd|Th)\s', lambda m: m.group(1) + m.group(2).lower()+'-', p.replace('-', ' ').title()) for p in parts[:-1]]
        file_dpath = "/".join(file_path_components)

        # Generate xpath from header path
        xpath_id_parts = [re.sub(r'^\d+', '', part) for part in parts]
        xpath = "//" + "//".join([f"section[@id='{p}']" for p in xpath_id_parts])

        source = resolve('source', 'unknown_source', section, global_data)

        new_section = {
            **global_data,
            'header_path': header_path,
            'section_name': resolve('section_name', section_name, section, global_data),
            'file_dpath': resolve('file_dpath', file_dpath, section, global_data),
            'xpath': resolve('xpath', xpath, section, global_data),
            'item_name': resolve('item_name', None, section, global_data),
            'item_id': resolve('item_id', None, section, global_data),

            # additional (global, etc) metadata goes here
            'type': resolve('type', None, section, global_data),
            'source': source,
        }
        return new_section

    try:
        with open("{{config_fpath}}", 'r') as f:
            data = yaml.safe_load(f)
    except FileNotFoundError:
        print(f"Error: Input file not found at '{{config_fpath}}'", file=sys.stderr)
        sys.exit(1)

    if 'sections' in data and isinstance(data['sections'], list):
        data['sections'] = [expand_section_metadata(section, data['global']) for section in data['sections']]

    with open("{{config_fpath}}", 'w') as f:
        yaml.dump(data, f, sort_keys=False, default_flow_style=False, indent=2)

    print(f"Successfully expanded metadata in '{{config_fpath}}'")
