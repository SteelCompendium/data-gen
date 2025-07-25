# Justfile module expected to be named "extract_hero_sections"

##################################################
# Constants and env vars
##################################################

log_prefix := "[JUST][extract_html_sections]"

input_dpath := `just _input_dpath` / 'heroes'
heroes_staging_dpath := `just _staging_dpath` / "heroes"
sections_staging_dpath := heroes_staging_dpath / "0_sections"

##################################################
# Public Recipes
##################################################

run heroes_html_fpath output_dpath:
    echo "Extracting Hero sections from '{{heroes_html_fpath}}'"
    just extract_heroes_sections _expand_and_extract "{{input_dpath}}/chapters.yml" "{{heroes_html_fpath}}" "{{output_dpath}}"
    just extract_heroes_sections _expand_and_extract "{{input_dpath}}/classes.yml" "{{heroes_html_fpath}}" "{{output_dpath}}"
    just extract_heroes_sections _expand_and_extract "{{input_dpath}}/common_abilities.yml" "{{heroes_html_fpath}}" "{{output_dpath}}"
    just extract_heroes_sections _expand_and_extract "{{input_dpath}}/movement.yml" "{{heroes_html_fpath}}" "{{output_dpath}}"
    just extract_heroes_sections _expand_and_extract "{{input_dpath}}/kits.yml" "{{heroes_html_fpath}}" "{{output_dpath}}"
    just extract_heroes_sections _expand_and_extract "{{input_dpath}}/ancestries.yml" "{{heroes_html_fpath}}" "{{output_dpath}}"
    just extract_heroes_sections _expand_and_extract "{{input_dpath}}/careers.yml" "{{heroes_html_fpath}}" "{{output_dpath}}"
    just extract_heroes_sections _expand_and_extract "{{input_dpath}}/cultures.yml" "{{heroes_html_fpath}}" "{{output_dpath}}"
    just extract_heroes_sections _expand_and_extract "{{input_dpath}}/complications.yml" "{{heroes_html_fpath}}" "{{output_dpath}}"
    just extract_heroes_sections _expand_and_extract "{{input_dpath}}/conditions.yml" "{{heroes_html_fpath}}" "{{output_dpath}}"
    just extract_heroes_sections _expand_and_extract "{{input_dpath}}/skills.yml" "{{heroes_html_fpath}}" "{{output_dpath}}"
    just extract_heroes_sections _expand_and_extract "{{input_dpath}}/negotiations.yml" "{{heroes_html_fpath}}" "{{output_dpath}}"
    just extract_heroes_sections _expand_and_extract "{{input_dpath}}/perks.yml" "{{heroes_html_fpath}}" "{{output_dpath}}"
    just extract_heroes_sections _expand_and_extract "{{input_dpath}}/titles.yml" "{{heroes_html_fpath}}" "{{output_dpath}}"
    just extract_heroes_sections _expand_and_extract "{{input_dpath}}/treasures.yml" "{{heroes_html_fpath}}" "{{output_dpath}}"
    # TODO - downtime stuff

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

