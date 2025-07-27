# Justfile module expected to be named "frontmatter"

##################################################
# Constants and env vars
##################################################

##################################################
# Public Recipes
##################################################

# processes the frontmatter for all markdown files in a directory
process_all md_dpath:
    #!/usr/bin/env bash
    set -euo pipefail
    find "{{md_dpath}}" -type f -name '*.md' | while read -r fpath; do
        just frontmatter process "$fpath"
    done

# Processes the frontmatter of a markdown file. Standard, common markdown edits.
process md_fpath:
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


    # capture name and parens
    #    m = re.match(r'^(.*?)\s*\((.*?)\)\s*$', header_name)
    #    if m:
    #        name, parens = m.group(1), m.group(2)
    #    else:
    #        # fallback if it doesn’t match the "foo (8 bar)" form
    #        name, parens = header_name, ''

    # remove unneeded metadata
    del data['header_path']
    del data['xpath']

    # Reassemble
    new_fm = yaml.safe_dump(data, sort_keys=False).rstrip()
    new_text = f"---\n{new_fm}\n---\n{body}"
    path.write_text(new_text, encoding="utf-8")

sort md_fpath:
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

    # Reassemble, sorted
    new_fm = yaml.safe_dump(data, sort_keys=True).rstrip()
    new_text = f"---\n{new_fm}\n---\n{body}"
    path.write_text(new_text, encoding="utf-8")

## Prints the frontmatter yaml of a markdown file
#_get md_fpath:
#    #!/usr/bin/env python3
#    import re, pathlib
#    import yaml
#    path = pathlib.Path('{{md_fpath}}')
#    text = path.read_text(encoding="utf-8")
#    # Split frontmatter & body
#    m = re.match(r'^---\s*\n(.*?)\n---\s*\n?.*$', text, flags=re.S)
#    print( m.group(1) if m else '')
#
## Sets the frontmatter on a markdown file (this replaces all existing frontmatter)
## yaml_fpath is a file containing the new yaml
#_set yaml_fpath md_fpath:
#    #!/usr/bin/env python3
#    import re, pathlib
#    import yaml
#
#    # Read in markdown file, extract body
#    path = pathlib.Path('{{md_fpath}}')
#    file_text = path.read_text(encoding="utf-8")
#    m = re.match(r'^---\s*\n.*?\n---\s*\n?(.*)$', file_text, flags=re.S)
#    body = m.group(1) if m else ''
#
#    # Reassemble, injecting frontmatter
#    yml_fm_text = pathlib.Path('{{yaml_fpath}}').read_text(encoding="utf-8")
#    new_text = f"---\n{yml_fm_text}\n---\n{body}"
#    path.write_text(new_text, encoding="utf-8")