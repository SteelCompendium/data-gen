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
        r'\1| --- | ---:|\n| **📏 \2** | **🎯 \3** |\n',
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

    #whitespace
    text = re.sub( r' +', r' ', text, flags=re.MULTILINE)
    # bullets
    text = re.sub( r'¥ ', r'', text, flags=re.MULTILINE)
    text = re.sub( r'¥', r'', text, flags=re.MULTILINE)
    # picture links
    text = re.sub( r'\n\!\[\]\(.*\.jpeg\)\n', r'', text, flags=re.MULTILINE)
    # page numbers
    text = re.sub( r'^\d\d?\d?\n+', r'', text, flags=re.MULTILINE)
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
    text = re.sub( r'^.$', "", text, flags=re.MULTILINE)
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
    text = re.sub( r' m\<', r' M <', text, flags=re.MULTILINE)
    text = re.sub( r' a\<', r' A <', text, flags=re.MULTILINE)
    text = re.sub( r' p\<', r' P <', text, flags=re.MULTILINE)
    text = re.sub( r' i\<', r' I <', text, flags=re.MULTILINE)
    text = re.sub( r' r\<', r' R <', text, flags=re.MULTILINE)
    text = re.sub( r'<(\d)]', r'< \1', text, flags=re.MULTILINE)

    # statblock
    # page number and side bar
    text = re.sub( r'^Draw Steel\n\d+', r'', text, flags=re.MULTILINE)
    text = re.sub( r'(Immunity\:.*((\n.*?)*)(\w\.|[a-z]))([A-Z].+) Level +(\d+) (.+)\n(.+) EV (.+)\n([1TSML2345]+[\d ]+\nSize ?Speed ?Stamina ?Stability ?Free ?Strike ?)', r'\n\n####### \5\n\n| \8 |         -         |      Level \6       |         \7          |        EV \9         |\n|:-----------------:|:-----------------:|:------------------:|:---------------------:|:--------------------:|\n\10\1', text, flags=re.MULTILINE)
    # statblock header and beginning of table
    text = re.sub( r'\.([\w ]+) Level (\d+) (.+)\n(.+) EV (.+)\n([1TSML2345]+[\d ]+\nSize ?Speed ?Stamina ?Stability ?Free ?Strike ?)', r'\n\n####### \1\n\n| \4 |         -         |      Level \2       |         \3          |        EV \5         |\n|:-----------------:|:-----------------:|:------------------:|:---------------------:|:--------------------:|\n\6', text, flags=re.MULTILINE)
    text = re.sub( r'\.([\w ]+) Level (\d+) (.+)\n(.+) EV (.+)', r'\n\n####### \1\n\n| \4 |         -         |      Level \2       |         \3          |        EV \5         |\n|:-----------------:|:-----------------:|:------------------:|:---------------------:|:--------------------:|', text, flags=re.MULTILINE)
    # middle of table
    text = re.sub( r'Immunity\: (.*) Weakness\: (.*)\nMovement\: (.*) With Captain\: (.*)', r'\n| **\1**<br>Immunity | **\3**<br>Movement |         -          | **\4**<br>With Captain | **\2**<br>Weaknesses  |', text, flags=re.MULTILINE)
    text = re.sub( r'Immunity\: (.*) Weakness\: (.*)\nMovement\: (.*)', r'\n| **\1**<br>Immunity | **\3**<br>Movement |         -          | **-**<br>With Captain | **\2**<br>Weaknesses  |', text, flags=re.MULTILINE)
    # characteristics
    text = re.sub( r'^M?M ight ([0-9\+\-]+) ?A gility ([0-9\+\-]+) ?R eason ([0-9\+\-]+) ?I ntuition ([0-9\+\-]+) ?P resence ([0-9\+\-]+)', r'|  **\1**<br>Might  | **\2**<br>Agility |  **\3**<br>Reason  |  **\4**<br>Intuition  |  **\5**<br>Presence  |', text, flags=re.MULTILINE)
    text = re.sub( r'^(1T|1M|1L|1S|\d) ?(\d)(\d)(\d)(\d)\nSize ?Speed ?Stamina ?Stability ?Free ?Strike ?', r'|   **\1**<br>Size   |  **\2**<br>Speed   | **\3**<br>Stamina |  **\4**<br>Stability   | **\5**<br>Free Strike |', text, flags=re.MULTILINE)
    text = re.sub( r'^(1T|1M|1L|1S|\d) ?(\d)(\d+)(\d)(\d)\nSize ?Speed ?Stamina ?Stability ?Free ?Strike ?', r'|   **\1**<br>Size   |  **\2**<br>Speed   | **\3**<br>Stamina |  **\4**<br>Stability   | **\5**<br>Free Strike |', text, flags=re.MULTILINE)
    text = re.sub( r'^(1T|1M|1L|1S|\d) ?(\d)(\d+)(\d) ?(\d)\nSize ?Speed ?Stamina ?Stability ?Free ?Strike ?', r'|   **\1**<br>Size   |  **\2**<br>Speed   | **\3**<br>Stamina |  **\4**<br>Stability   | **\5**<br>Free Strike |', text, flags=re.MULTILINE)

    # monster book
    text = re.sub( r'^\#* ?t \**([A-Z].*)\**', r'\n⭐️ **\1**\n\n', text, flags=re.MULTILINE)
    text = re.sub( r'^\#* ?s \**([A-Z].*)\**', r'\n👤 **\1**\n\n', text, flags=re.MULTILINE)
    text = re.sub( r'^\#* ?p \**([A-Z].*)\**', r'\n🌀 **\1**\n\n', text, flags=re.MULTILINE)
    text = re.sub( r'^\#* ?d \**([A-Z].*)\**', r'\n☠️ **\1**\n\n', text, flags=re.MULTILINE)
    text = re.sub( r'^\#* ?a \**([A-Z].*)\**', r'\n🔳 **\1**\n\n', text, flags=re.MULTILINE)
    text = re.sub( r'^\#* ?r \**([A-Z].*)\**', r'\n🏹 **\1**\n\n', text, flags=re.MULTILINE)
    text = re.sub( r'^\#* ?m \**([A-Z].*)\**', r'\n🗡 **\1**\n\n', text, flags=re.MULTILINE)
    text = re.sub( r'^\#* ?! \**([A-Z].*)\**', r'\n❗️ **\1**\n\n', text, flags=re.MULTILINE)
    text = re.sub( r'^\#* ?b \**([A-Z].*)\**', r'\n❇️ **\1**\n\n', text, flags=re.MULTILINE)
    text = re.sub( r'^\#* ?⚔ \**([A-Z].*)\**', r'\n⚔️ **\1**\n\n', text, flags=re.MULTILINE)
    text = re.sub( r'^\#* ?v \**([A-Z].*)\**', r'\n⚔️ **\1**\n\n', text, flags=re.MULTILINE)

    # Power roll in header (statblocks)
    text = re.sub( r'^(.*) 2d10 ?\+ ?(\d+) ?(\*\*)', r'\1\3\n**Power Roll + \2:**', text, flags=re.MULTILINE)
    text = re.sub( r'^(.*) 2d10 ?\+ ?(\d+) (.+)\*\*', r'\1 (\3)**\n\n**Power Roll + \2:**', text, flags=re.MULTILINE)

    # ability table
    text = re.sub( r'^([A-Za-z, \-]+) ([A-Z]{1}[a-z ]+action|Maneuver)', r'| **\1** | **\2** |', text, flags=re.MULTILINE)
    text = re.sub( r'\| *Melee 1 *\| *One creature *\|', r'| **📏 Melee 1**            | **🎯 One creature** |', text, flags=re.MULTILINE)
    text = re.sub( r'\| *Melee 1 *\| *One creature or object*\|', r'| **📏 Melee 1**            | **🎯 One creature or object** |', text, flags=re.MULTILINE)
    text = re.sub( r'^e ?([\w, ;]+) x ([\w, ]+)', r'| **📏 \1** | **🎯 \2** |', text, flags=re.MULTILINE)
    text = re.sub( r' \| \| \-\-\- \| \-\-\-\:\|', r' |\n| --- | ---:|', text, flags=re.MULTILINE)
    text = re.sub( r'\*\* \|\n\| \*\*📏', r'** |\n| --- | ---:|\n| **📏', text, flags=re.MULTILINE)

    # Power rolls
    text = re.sub( r'^\#* ?Power Roll \+ ([^\*]*) *\** *\:\**', r'\n\n**Power Roll + \1:**', text, flags=re.MULTILINE)

    # Malice
    text = re.sub( r'^\**(\d+) Malice\**\:\**\s*', r'\n**\1 Malice:** ', text, flags=re.MULTILINE)

    # power roll tiers
    text = re.sub( r'\s*\-? ?á ?', r'\n\n- **≤11:** ', text, flags=re.MULTILINE)
    text = re.sub( r'\s*\-? ?é ?', r'\n- **12-16:** ', text, flags=re.MULTILINE)
    text = re.sub( r'\s*\-? ?í ?', r'\n- **17+:** ', text, flags=re.MULTILINE)

    text = re.sub( r'^\-? ?1 ', r'\n- **≤11:** ', text, flags=re.MULTILINE)
    text = re.sub( r'^\-? ?2 ', r'- **12-16:** ', text, flags=re.MULTILINE)
    text = re.sub( r'^\-? ?3 ', r'- **17+:** ', text, flags=re.MULTILINE)

    # move power rolls to correct spot
    text = re.sub( r'^(\*\*Power Roll \+ \d+\:\*\*)\n((\n.*?)*)(\- \*\*≤)', r'\2\1\n\n\4', text, flags=re.MULTILINE)

    # keywords
    text = re.sub( r'^\**Trigger\**\:\**', r'\n**Trigger:**', text, flags=re.MULTILINE)
    text = re.sub( r'^\**Special\**\:\**', r'\n**Special:**', text, flags=re.MULTILINE)
    text = re.sub( r'^\**Effect\**\:\**', r'\n**Effect:**', text, flags=re.MULTILINE)
    text = re.sub( r'^\**Effect\**\:?\** ([A-Z])', r'\n**Effect:** \1', text, flags=re.MULTILINE)

    # image text
    text = re.sub( r'Image\: [^\|]*icon ', r'', text, flags=re.MULTILINE)
    text = re.sub( r'Image\: [^\|]*icon[^ ]', r'', text, flags=re.MULTILINE)

    # abilities
    text = re.sub( r'\#+ \*\*(.*) \((.*)\)\*\*', r'######## \1 (\2)', text, flags=re.MULTILINE)
    text = re.sub( r'^\#\# \*\*(.*)\*\*', r'#### \1', text, flags=re.MULTILINE)
    text = re.sub( r'^\#\#\#\# \*\*(.*)\*\*', r'######## \1', text, flags=re.MULTILINE)

    # known ability types
    text = re.sub( r'([^\(])(Villain Action 1)([^\)])', r'\1(\2)\3', text, flags=re.MULTILINE)
    text = re.sub( r'([^\(])(Villain Action 2)([^\)])', r'\1(\2)\3', text, flags=re.MULTILINE)
    text = re.sub( r'([^\(])(Villain Action 3)([^\)])', r'\1(\2)\3', text, flags=re.MULTILINE)
    text = re.sub( r'([^\(])(Signature Ability)([^\)])', r'\1(\2)\3', text, flags=re.MULTILINE)

    # apostrophes
    text = re.sub( r"([a-z])\' ([slt])", r"\1'\2", text, flags=re.MULTILINE)

    # newlines
    text = re.sub( r'\n\n\n', r'\n\n', text, flags=re.MULTILINE)
    text = re.sub( r'\n\n\n', r'\n\n', text, flags=re.MULTILINE)

    # write it all out at once
    with open(output_path, 'w', encoding='utf-8') as f:
        f.write(text)
