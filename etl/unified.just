# Justfile module expected to be named "unified"
# Handles collecting markdown sources from various repos and assembling them into one unified repo

##################################################
# Constants and env vars
##################################################

steel_compendium_dpath := `just _steel_compendium_dpath`

unified_staging_dpath := `just _staging_dpath` / "unified"
unified_linked_staging_dpath := `just _staging_dpath` / "unified-linked"

unified_dse_staging_dpath := `just _staging_dpath` / "unified-dse"
linked_unified_dse_staging_dpath := `just _staging_dpath` / "unified-dse-linked"

# Input/sources (unlinked)
rules_md_source_dpath := steel_compendium_dpath / "data-rules-md"
rules_dse_md_source_dpath := steel_compendium_dpath / "data-rules-md-dse"
bestiary_md_source_dpath := steel_compendium_dpath / "data-bestiary-md"
bestiary_dse_md_source_dpath := steel_compendium_dpath / "data-bestiary-md-dse"
adventures_md_source_dpath := steel_compendium_dpath / "data-adventures-md"

# Input/sources (linked)
linked_rules_md_source_dpath := steel_compendium_dpath / "data-rules-md-linked"
linked_rules_dse_md_source_dpath := steel_compendium_dpath / "data-rules-md-dse-linked"
# TODO - change to linked
linked_bestiary_md_source_dpath := steel_compendium_dpath / "data-bestiary-md"
# TODO - change to linked
linked_bestiary_dse_md_source_dpath := steel_compendium_dpath / "data-bestiary-md-dse"
# TODO - change to linked
linked_adventures_md_source_dpath := steel_compendium_dpath / "data-adventures-md"

##################################################
# Public Recipes
##################################################

export BASH_ENV := ".utils/.utilsrc"
set shell := ["bash", "-c"]

gen_unified:
    #!/usr/bin/env bash
    set -euo pipefail
    just _wipe_dir "{{unified_staging_dpath}}"

    # unlinked data
    just unified _gen_unified_md \
        "{{unified_staging_dpath}}" \
        "{{rules_md_source_dpath}}" \
        "{{bestiary_md_source_dpath}}" \
        "{{adventures_md_source_dpath}}"
    just _copy_data_to_repo "{{unified_staging_dpath}}" "data-md"

    # linked data
    just unified _gen_unified_md \
        "{{unified_linked_staging_dpath}}" \
        "{{linked_rules_md_source_dpath}}" \
        "{{linked_bestiary_md_source_dpath}}" \
        "{{linked_adventures_md_source_dpath}}"
    just _copy_data_to_repo "{{unified_linked_staging_dpath}}" "data-md-linked"

    # unlinked dse
    just unified _gen_unified_md_dse \
        "{{unified_dse_staging_dpath}}" \
        "{{rules_dse_md_source_dpath}}" \
        "{{bestiary_dse_md_source_dpath}}" \
        "{{adventures_md_source_dpath}}"
    just _copy_data_to_repo "{{unified_dse_staging_dpath}}" "data-md-dse"

    # linked dse
    just unified _gen_unified_md_dse \
        "{{linked_unified_dse_staging_dpath}}" \
        "{{linked_rules_dse_md_source_dpath}}" \
        "{{linked_bestiary_dse_md_source_dpath}}" \
        "{{linked_adventures_md_source_dpath}}"
    just _copy_data_to_repo "{{linked_unified_dse_staging_dpath}}" "data-md-dse-linked"

##################################################
# Private Recipes
##################################################

[private]
_gen_unified_md staging_dpath rules_dpath bestiary_dpath adventures_dpath:
    #!/usr/bin/env bash
    set -euo pipefail

    # Unify sources. Use rsync to avoid .git dir
    just _print_section "Unified: Pulling sources to common dir ({{staging_dpath}})"
    mkdir -p "{{staging_dpath}}"
    rsync -a "{{rules_dpath}}"/* "{{staging_dpath}}/Rules" --exclude '.git' --exclude 'LICENSE'
    rsync -a "{{bestiary_dpath}}"/* "{{staging_dpath}}/Bestiary" --exclude '.git' --exclude 'LICENSE'
    rsync -a "{{adventures_dpath}}"/* "{{staging_dpath}}/Adventures" --exclude '.git' --exclude 'LICENSE'
    # TODO - I should format the files?  They _should_ already be formatted...

[private]
_gen_unified_md_dse staging_dpath rules_dpath bestiary_dpath adventures_dpath:
    #!/usr/bin/env bash
    set -euo pipefail

    # Unify sources. Use rsync to avoid .git dir
    just _print_section "Unified: Pulling DSE sources to common dir ({{staging_dpath}})"
    mkdir -p "{{staging_dpath}}"
    rsync -a "{{rules_dpath}}"/* "{{staging_dpath}}/Rules" --exclude '.git' --exclude 'LICENSE'
    rsync -a "{{bestiary_dpath}}"/* "{{staging_dpath}}/Bestiary" --exclude '.git' --exclude 'LICENSE'
    rsync -a "{{adventures_dpath}}"/* "{{staging_dpath}}/Adventures" --exclude '.git' --exclude 'LICENSE'
