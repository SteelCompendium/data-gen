# Justfile module expected to be named "monsters_sections"

##################################################
# Constants and env vars
##################################################

log_prefix := "[JUST][hero_sections]"

input_dpath := `just _input_dpath` / 'monsters'
monsters_staging_dpath := `just _staging_dpath` / "monsters"
sections_staging_dpath := monsters_staging_dpath / "0_sections"

section_list := '"basics"'
section_config_yml_filenames := '"basics.yml"'

##################################################
# Public Recipes
##################################################

# TODO - add downtime stuff
# Extracts items from html using section_config.yml files
extract monsters_html_fpath output_dpath:
    #!/usr/bin/env bash
    set -euo pipefail
    echo "Extracting Hero sections from '{{monsters_html_fpath}}'"
    configs=( {{section_config_yml_filenames}} )
    for config in "${configs[@]}"; do
        just monsters_sections _expand_and_extract "{{input_dpath}}/${config}" "{{monsters_html_fpath}}" "{{output_dpath}}"
    done

# Generates an index.md file for each section
gen_indexes root_dpath:
    #!/usr/bin/env bash
    set -euo pipefail
    # TODO - I could spell all these out, but I think I should connect it to the section.yml files?
    sections=( {{section_list}} )
    for section in "${sections[@]}"; do
        case "$section" in
          # TODO
          Treasures) index_columns="file_name treasure_type" ;;
          *) index_columns="file_name" ;;
        esac

        just index gen "{{root_dpath}}/${section}" "{{root_dpath}}/${section}/_Index.md" "$index_columns" "$section"
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

