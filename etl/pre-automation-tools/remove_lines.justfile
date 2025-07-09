# Usage: just remove_lines path/to/input.md path/to/output.md
run input_md_path output_md_path:
    #!/usr/bin/env python3
    import re, sys

    # 1) Exact lines to remove
    remove_exact = {
        "![crosshair icon](image-url)",
        "i",
        "iv",
        "![A bullseye or crosshair symbol.](image-url)",
    }

    # 2) Regex patterns to remove (full-line matches)
    remove_patterns = [
        re.compile(r'!\[\]\(_page_\d+_Picture_\d+\.jpeg\)'),
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
