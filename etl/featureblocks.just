# Justfile module expected to be named "featureblocks"

##################################################
# Constants and env vars
##################################################

##################################################
# Public Recipes
##################################################

# Converts featureblock markdown into another format (yaml, json, etc)
convert_all md_dpath output_format output_dpath:
    #!/usr/bin/env bash
    set -euo pipefail
    echo >&2 "Featureblocks: converting markdown to '{{output_format}}'"
    mkdir -p "{{output_dpath}}"
    npx sc-convert \
        --type featureblock \
        --from markdown \
        --to "{{output_format}}" \
        --output "{{output_dpath}}" \
        "{{md_dpath}}"

# Converts featureblock markdown into another format (yaml, json, etc) and prints output
convert md_fpath output_format:
    #!/usr/bin/env bash
    set -euo pipefail
    npx sc-convert \
        --type featureblock \
        --from markdown \
        --to "{{output_format}}" \
        "{{md_fpath}}"

# For each markdown file in md_dpath, the body gets replaced with a DSE codeblock for a featureblock
embed_featureblocks md_dpath yaml_dpath:
    echo "Not yet implemented.  This code is duplicated in the abilities and statblock, only diff is the codeblock lang"
