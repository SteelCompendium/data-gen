# Justfile module expected to be named "heroes_sections"

# TODO - frontmatter gen should also be in here?

##################################################
# Constants and env vars
##################################################

log_prefix := "[JUST][hero_sections]"

input_dpath := `just _input_dpath` / 'heroes'
heroes_staging_dpath := `just _staging_dpath` / "heroes"
sections_staging_dpath := heroes_staging_dpath / "0_sections"

# TODO - Abilities not included
# TODO - Negotiation/Motivations adn Pitfalls not included
section_list := '"Ancestries" "Careers" "Chapters" "Classes" "Complications" "Conditions" "Cultures" "Kits" "Movement" "Perks" "Skills" "Titles" "Treasures"'

# abilities.yml missing
section_config_yml_filenames := '"ability_fixes.yml" "chapters.yml" "classes.yml" "common_abilities.yml" "movement.yml" "kits.yml" "ancestries.yml" "careers.yml" "cultures.yml" "complications.yml" "conditions.yml" "skills.yml" "negotiations.yml" "perks.yml" "titles.yml" "treasures.yml"'

##################################################
# Public Recipes
##################################################

# TODO - add downtime stuff
# Extracts items from html using section_config.yml files
extract heroes_html_fpath output_dpath:
    #!/usr/bin/env bash
    set -euo pipefail
    echo "Extracting Hero sections from '{{heroes_html_fpath}}'"
    configs=( {{section_config_yml_filenames}} )
    for config in "${configs[@]}"; do
        just heroes_sections _expand_and_extract "{{input_dpath}}/${config}" "{{heroes_html_fpath}}" "{{output_dpath}}"
    done

# Generates an index.md file for each section
gen_indexes root_dpath:
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

# helper to expand a config and then extract it
_expand_and_extract config_fpath html_fpath output_dpath:
    #!/usr/bin/env bash
    set -euo pipefail
    mkdir -p "{{output_dpath}}"
    mkdir -p "{{sections_staging_dpath}}"
    expanded_config_fpath="{{sections_staging_dpath}}/$(basename "{{config_fpath}}")"
    cp "{{config_fpath}}" "$expanded_config_fpath"
    just section_config expand_general "$expanded_config_fpath"
    just extract_html_sections extract_sections "$expanded_config_fpath" "{{html_fpath}}" "{{output_dpath}}" "skip_delete"

