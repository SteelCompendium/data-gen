gen md_fpath:
    #!/usr/bin/env python3
    import re
    import yaml
    import sys
    
    # capture name and parens
    m = re.match(r'^(.*?)\s*\((.*?)\)\s*$', header_name)
    if m:
        name, parens = m.group(1), m.group(2)
    else:
        # fallback if it doesn’t match the "foo (8 bar)" form
        name, parens = header_name, ''