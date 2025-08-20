# Justfile module expected to be named "unified"
# Handles collecting markdown sources from various repos and assembling them into one unified repo

##################################################
# Constants and env vars
##################################################

steel_compendium_dpath := `just _steel_compendium_dpath`
unified_staging_dpath := `just _staging_dpath` / "unified"
unified_unlinked_dpath := unified_staging_dpath / "unlinked"
unified_linked_dpath := unified_staging_dpath / "linked"

unified_dse_staging_dpath := `just _staging_dpath` / "unified-dse"

# Input/sources
rules_md_source_dpath := steel_compendium_dpath / "data-rules-md"
rules_dse_md_source_dpath := steel_compendium_dpath / "data-rules-md-dse"
bestiary_md_source_dpath := steel_compendium_dpath / "data-bestiary-md"
bestiary_dse_md_source_dpath := steel_compendium_dpath / "data-bestiary-md-dse"
adventures_md_source_dpath := steel_compendium_dpath / "data-adventures-md"

##################################################
# Public Recipes
##################################################

export BASH_ENV := ".utils/.utilsrc"
set shell := ["bash", "-c"]

gen_unified:
    #!/usr/bin/env bash
    set -euo pipefail
    just _wipe_dir "{{unified_staging_dpath}}"

    just unified _gen_unified_md
    just _copy_data_to_repo "{{unified_linked_dpath}}" "data-md"

    just unified _gen_unified_md_dse
    just _copy_data_to_repo "{{unified_dse_staging_dpath}}" "data-md-dse"

##################################################
# Private Recipes
##################################################

[private]
_gen_unified_md:
    #!/usr/bin/env bash
    set -euo pipefail

    # Unify sources. Use rsync to avoid .git dir
    just _print_section "Unified: Pulling sources to common dir ({{unified_unlinked_dpath}})"
    mkdir -p "{{unified_unlinked_dpath}}"
    rsync -a "{{rules_md_source_dpath}}"/* "{{unified_unlinked_dpath}}/Rules" --exclude '.git' --exclude 'LICENSE'
    rsync -a "{{bestiary_md_source_dpath}}"/* "{{unified_unlinked_dpath}}/Bestiary" --exclude '.git' --exclude 'LICENSE'
    rsync -a "{{adventures_md_source_dpath}}"/* "{{unified_unlinked_dpath}}/Adventures" --exclude '.git' --exclude 'LICENSE'
    # TODO - I should format the unlinked files?  They _should_ already be formatted...

    # TODO - add linking.  For now, just copy unlinked into fake linked dir
    mkdir -p "{{unified_linked_dpath}}"
    cp -R "{{unified_unlinked_dpath}}"/* "{{unified_linked_dpath}}"

    #    # Link MD section files to each other
    #    just _print_section "Unified: Linking unified files"
    #    mkdir -p "{{unified_linked_dpath}}"
    #    just -f link_md/justfile run "{{unified_unlinked_dpath}}" "{{unified_linked_dpath}}"
    #
    #    # Format/Lint the linked markdown files
    #    just _print_section "Unified: Formatting unified, linked files"
    #    just markdown lint "{{unified_linked_dpath}}"

[private]
_gen_unified_md_dse:
    #!/usr/bin/env bash
    set -euo pipefail

    # Unify sources. Use rsync to avoid .git dir
    just _print_section "Unified: Pulling DSE sources to common dir ({{unified_dse_staging_dpath}})"
    mkdir -p "{{unified_dse_staging_dpath}}"
    rsync -a "{{rules_dse_md_source_dpath}}"/* "{{unified_dse_staging_dpath}}/Rules" --exclude '.git' --exclude 'LICENSE'
    rsync -a "{{bestiary_dse_md_source_dpath}}"/* "{{unified_dse_staging_dpath}}/Bestiary" --exclude '.git' --exclude 'LICENSE'
    rsync -a "{{adventures_md_source_dpath}}"/* "{{unified_dse_staging_dpath}}/Adventures" --exclude '.git' --exclude 'LICENSE'
