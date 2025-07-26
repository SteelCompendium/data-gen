# Justfile module expected to be named "section_indexing"

# TODO - this file should merge with heroes_sections
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
        just index gen "{{root_dpath}}/${section}" "{{root_dpath}}/${section}/Index.md" "file_name" "$section"
    done

##################################################
# Private Recipes
##################################################
