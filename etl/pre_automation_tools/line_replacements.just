# Usage: just remove_lines path/to/input.md path/to/output.md
# ~/code/personal/steelCompendium $ just -f data-gen/etl/pre-automation-tools/line_replacements.justfile run data-gen/input/heroes/Draw\ Steel\ RC\ for\ Patrons.md data-gen/temp/line_replacements.md

#
# Removes a predefined set of lines that are not needed (images, copyright, etc)

[no-cd]
run input_md_path output_md_path:
    #!/usr/bin/env python3
    import re, sys

    # usage: ./fix.py input.md output.md
    input_path, output_path = "{{input_md_path}}", "{{output_md_path}}" 

    # 1) slurp the whole file
    with open(input_path, 'r', encoding='utf-8') as f:
        text = f.read()

    # 2) first pass: insert header & table row before your “e Ranged X x Y” lines
    text = re.sub(
        r'^(.*?)e ([rR]anged \d+|[mM]elee \d+|\d+ [aA]ura|\d+ [bB]urst|\d+ [cC]ube|\d+ [lL]ine|\d+ [wW]all|[sS]elf) x (.*)',
        r'\1\n| --- | ---:|\n| **📏 \2** | **🎯 \3** |',
        text,
        flags=re.MULTILINE
    )

    # second pass: turn your other headings into table rows
    text = re.sub(
        r'^[\|#\s\*]+(.*?)[\|\s]+'
        r'(Main [aA]ction|Maneuver|Free [mM]aneuver|Triggered|Free [tT]riggered)'
        r'[\s\*\|]+$',
        "\n" + r'| **\1** | **\2** |' + "\n",
        text,
        flags=re.MULTILINE
    )

    # extra newline in tables
    text = re.sub(
        r'\|\n\n\|\s?\-\-',
        r'|\n| --',
        text,
        flags=re.MULTILINE
    )

    # bullets
    text = re.sub( r'¥ ', r'', text, flags=re.MULTILINE)
    # picture links
    text = re.sub( r'\n\!\[\]\(.*\.jpeg\)\n', r'', text, flags=re.MULTILINE)
    # page numbers
    text = re.sub( r'^\d+\n*', r'', text, flags=re.MULTILINE)
    # html bold
    text = re.sub( r'\<\/?b\>', r'**', text, flags=re.MULTILINE)
    # weak, average, strong
    text = re.sub( r'\s?<\s?w\s?,', r' < WEAK,', text, flags=re.MULTILINE)
    text = re.sub( r'\s?<\s?v\s?,', r' < AVERAGE,', text, flags=re.MULTILINE)
    text = re.sub( r'\s?<\s?s\s?,', r' < STRONG,', text, flags=re.MULTILINE)

    # write it all out at once
    with open(output_path, 'w', encoding='utf-8') as f:
        f.write(text)
