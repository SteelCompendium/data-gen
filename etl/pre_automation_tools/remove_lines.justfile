# Usage: just remove_lines path/to/input.md path/to/output.md
# ~/code/personal/steelCompendium $ just -f data-gen/etl/pre-automation-tools/remove_lines.justfile run data-gen/Rules/Draw\ Steel\ RC\ for\ Patrons.md data-gen/temp/removed_lines_output.md
#
# Removes a predefined set of lines that are not needed (images, copyright, etc)

[no-cd]
run input_md_path output_md_path:
    #!/usr/bin/env python3
    import re, sys

    # 1) Exact lines to remove
    remove_exact = {
        "i",
        "ii",
        "iii",
        "iv",
        "v",
        "vi",
        ".",
        "⊕",
        "Draw Steel",
    }

    # 2) Regex patterns to remove (full-line matches)
    remove_patterns = [
        re.compile(r'!\[\]\(_page_\d+_Picture_\d+\.jpeg\)'),
        re.compile(r'!\[.*\]\(.*\)'),
        re.compile(r'Chapter\s\d+'),
    ]

    # 3) Process file
    with open('{{input_md_path}}', encoding='utf-8') as inp, \
         open('{{output_md_path}}', 'w', encoding='utf-8') as out:
        for line in inp:
            stripped = line.rstrip('\n')
            # skip if exact match
            if stripped in remove_exact:
                continue
            # skip if any regex fullmatches
            if any(p.fullmatch(stripped) for p in remove_patterns):
                continue
            out.write(line)
