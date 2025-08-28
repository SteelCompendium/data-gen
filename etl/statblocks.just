# Justfile module expected to be named "statblocks"

# # Extract ability html from single html file (note, the html file needs to be generated. Run in devbox
# devbox shell
# just -f abilities.just extract_sections "../input/heroes/abilities.yml" "../staging/heroes/1_html/Draw Steel Heroes.html" "../staging/heroes/2_html_sections/Abilities"

##################################################
# Constants and env vars
##################################################

##################################################
# Public Recipes
##################################################


# Converts statblock markdown into another format (yaml, json, etc)
convert_all md_dpath output_format output_dpath:
    #!/usr/bin/env bash
    set -euo pipefail
    echo >&2 "Statblocks: converting markdown to '{{output_format}}'"
    mkdir -p "{{output_dpath}}"
    sc-convert \
        --type statblock \
        --from markdown \
        --to "{{output_format}}" \
        --output "{{output_dpath}}" \
        "{{md_dpath}}"

# Converts statblock markdown into another format (yaml, json, etc) and prints output
convert md_fpath output_format:
    #!/usr/bin/env bash
    set -euo pipefail
    sc-convert \
        --type statblock \
        --from markdown \
        --to "{{output_format}}" \
        "{{md_fpath}}"
