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
    # newlines
    #text = re.sub( r'\<br\>', r' ', text, flags=re.MULTILINE)
    text = re.sub( r'\n\n\n', r'\n\n', text, flags=re.MULTILINE)
    # unicode
    text = re.sub( r' ?…', r'...', text, flags=re.MULTILINE)
    text = re.sub( r'[“”]', r'"', text, flags=re.MULTILINE)
    text = re.sub( r'[‘’]', "'", text, flags=re.MULTILINE)
    text = re.sub( r'[—–]', "-", text, flags=re.MULTILINE)
    text = re.sub( r'×', "x", text, flags=re.MULTILINE)
    # remove spans and sups
    text = re.sub( r'\<span id\=\".*"\>\<\/span\>', r'', text, flags=re.MULTILINE)
    text = re.sub( r'\<span\>', r'', text, flags=re.MULTILINE)
    text = re.sub( r'\<\/span\>', r'', text, flags=re.MULTILINE)
    text = re.sub( r'\<sup\>', r'', text, flags=re.MULTILINE)
    text = re.sub( r'\<\/sup\>', r'', text, flags=re.MULTILINE)
    # flavor
    text = re.sub( r'(.*)\<i\>(.*)\<\/i\>(.*)', r'*\2*\n\n\1 \3', text, flags=re.MULTILINE)
    # weak, average, strong
    text = re.sub( r'\s?<\s?w\s', r' < WEAK ', text, flags=re.MULTILINE)
    text = re.sub( r'\s?<\s?v\s', r' < AVERAGE ', text, flags=re.MULTILINE)
    text = re.sub( r'\s?<\s?s\s', r' < STRONG ', text, flags=re.MULTILINE)
    text = re.sub( r'WEAK ,', r'WEAK,', text, flags=re.MULTILINE)
    text = re.sub( r'AVERAGE ,', r'AVERAGE,', text, flags=re.MULTILINE)
    text = re.sub( r'STRONG ,', r'STRONG,', text, flags=re.MULTILINE)
    # char potency
    text = re.sub( r'm \<', r'M <', text, flags=re.MULTILINE)
    text = re.sub( r'a \<', r'A <', text, flags=re.MULTILINE)
    text = re.sub( r'p \<', r'P <', text, flags=re.MULTILINE)
    text = re.sub( r'i \<', r'I <', text, flags=re.MULTILINE)
    text = re.sub( r'r \<', r'R <', text, flags=re.MULTILINE)

    text = re.sub( r'\| *Melee 1 *\| *One creature *\|', r'| **📏 Melee 1**            | **🎯 One creature** |', text, flags=re.MULTILINE)
    text = re.sub( r'\| *Melee 1 *\| *One creature or object*\|', r'| **📏 Melee 1**            | **🎯 One creature or object** |', text, flags=re.MULTILINE)

    # Power rolls
    text = re.sub( r'^\#* ?Power Roll \+ ([^\*]*) *\** *\:\**', r'**Power Roll + \1:**', text, flags=re.MULTILINE)

    # power roll tiers
    text = re.sub( r'\s*\-? ?á ?', r'\n\n- **≤11:** ', text, flags=re.MULTILINE)
    text = re.sub( r'\s*\-? ?é ?', r'\n- **12-16:** ', text, flags=re.MULTILINE)
    text = re.sub( r'\s*\-? ?í ?', r'\n- **17+:** ', text, flags=re.MULTILINE)
    # keywords
    text = re.sub( r'^\**Trigger\**\:\**', r'**Trigger:**', text, flags=re.MULTILINE)
    text = re.sub( r'^\**Effect\**\:\**', r'**Effect:**', text, flags=re.MULTILINE)
    # image text
    text = re.sub( r'Image\: [^\|]*icon ', r'', text, flags=re.MULTILINE)
    text = re.sub( r'Image\: [^\|]*icon[^ ]', r'', text, flags=re.MULTILINE)

    # abilities
    text = re.sub( r'\#* \*\*(.*) \((.*)\)\*\*', r'######## \1 (\2)', text, flags=re.MULTILINE)
    text = re.sub( r'^\#\# \*\*(.*)\*\*', r'#### \1', text, flags=re.MULTILINE)
    text = re.sub( r'^\#\#\#\# \*\*(.*)\*\*', r'######## \1', text, flags=re.MULTILINE)

    # monster book
    text = re.sub( r'^\#* t \*\*(.*)\*\*', r'⭐️ **\1**', text, flags=re.MULTILINE)
    text = re.sub( r'^\#* s \*\*(.*)\*\*', r'👤 **\1**', text, flags=re.MULTILINE)
    text = re.sub( r'^\#* p \*\*(.*)\*\*', r'🌀 **\1**', text, flags=re.MULTILINE)
    text = re.sub( r'^\#* d \*\*(.*)\*\*', r'☠️ **\1**', text, flags=re.MULTILINE)
    text = re.sub( r'^\#* a \*\*(.*)\*\*', r'🔳 **\1**', text, flags=re.MULTILINE)
    text = re.sub( r'^\#* r \*\*(.*)\*\*', r'🏹 **\1**', text, flags=re.MULTILINE)
    text = re.sub( r'^\#* m \*\*(.*)\*\*', r'🗡 **\1**', text, flags=re.MULTILINE)
    text = re.sub( r'^\#* ! \*\*(.*)\*\*', r'❗️ **\1**', text, flags=re.MULTILINE)
    text = re.sub( r'^\#* b \*\*(.*)\*\*', r'❇️ **\1**', text, flags=re.MULTILINE)
    text = re.sub( r'^\#* ⚔ \*\*(.*)\*\*', r'⚔️ **\1**', text, flags=re.MULTILINE)
    text = re.sub( r'^\#* v \*\*(.*)\*\*', r'⚔️ **\1**', text, flags=re.MULTILINE)


    # newlines
    text = re.sub( r'\n\n\n', r'\n\n', text, flags=re.MULTILINE)


    # write it all out at once
    with open(output_path, 'w', encoding='utf-8') as f:
        f.write(text)
