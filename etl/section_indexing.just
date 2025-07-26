# Justfile module expected to be named "section_indexing"

# TODO - this file should merge with extract_heroes_sections
# TODO - frontmatter gen should also be in here?

##################################################
# Constants and env vars
##################################################

# TODO - Abilities not included
# TODO - Negotiation/Motivations adn Pitfalls not included
section_list := '"Ancestries" "Careers" "Chapters" "Classes" "Complications" "Conditions" "Cultures" "Kits" "Movement" "Perks" "Skills" "Titles" "Treasures"'

##################################################
# Public Recipes
##################################################

gen_all_sections root_dpath:
    #!/usr/bin/env bash
    set -euo pipefail
    # TODO - I could spell all these out, but I think I should connect it to the section.yml files?
    sections=( {{section_list}} )
    for section in "${sections[@]}"; do
        just section_indexing gen_index "{{root_dpath}}/${section}"
    done

# depth=0 means only the dirs in the dpath
# depth=1 means nested children (one-level) are included as well
gen_index md_dpath depth="0":
    #!/usr/bin/env bash
    set -euo pipefail
    just _print_section "Generating indexes"
    echo >&2 "    Parent dpath: '{{md_dpath}}'"
    echo >&2

    if [ ! -d "{{md_dpath}}" ]; then
        echo >&2 "    [WARNING] Cannot generate index: missing parent dpath '{{md_dpath}}'"
        exit
    fi

    to_index="{{md_dpath}}"
    index_fpath="${to_index}/Index.md"
    title="$(basename "$to_index")"
    just index gen "$to_index" "$index_fpath" "file_name" "$title"

##################################################
# Private Recipes
##################################################
