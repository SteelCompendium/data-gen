# Justfile module expected to be named "unified"
# Handles collecting markdown sources from various repos and assembling them into one unified repo

##################################################
# Constants and env vars
##################################################

steel_compendium_dpath := `just _steel_compendium_dpath`
unified_staging_dpath := `just _staging_dpath` / "unified"
unified_unlinked_dpath := unified_staging_dpath / "unlinked"
unified_linked_dpath := unified_staging_dpath / "linked"

# Input/sources
rules_md_source_dpath := steel_compendium_dpath / "data-rules-md"
bestiary_md_source_dpath := steel_compendium_dpath / "data-bestiary-md"
adventures_md_source_dpath := steel_compendium_dpath / "data-adventures-md"

##################################################
# Public Recipes
##################################################

export BASH_ENV := ".utils/.utilsrc"
set shell := ["bash", "-c"]

gen_unified: (wipe unified_staging_dpath)
    #!/usr/bin/env bash
    set -euo pipefail
    just unified gen_unified_md
    just unified assemble_unified

gen_unified_md:
    #!/usr/bin/env bash
    set -euo pipefail

    # Unify sources. Use rsync to avoid .git dir
    just _print_section "Unified: Pulling sources to common dir"
    mkdir -p "{{unified_unlinked_dpath}}"
    rsync -a "{{rules_md_source_dpath}}"/* "{{unified_unlinked_dpath}}/Rules" --exclude '.git'
    rsync -a "{{bestiary_md_source_dpath}}"/* "{{unified_unlinked_dpath}}/Bestiary" --exclude '.git'
    rsync -a "{{adventures_md_source_dpath}}"/* "{{unified_unlinked_dpath}}/Adventures" --exclude '.git'
    # TODO - I should format the unlinked files?  They _should_ already be formatted...

    # TODO - add linking.  For now, just copy unlinked into fake linked dir
    cp -R "{{unified_unlinked_dpath}}"/* "{{unified_linked_dpath}}"

    #    # Link MD section files to each other
    #    just _print_section "Unified: Linking unified files"
    #    mkdir -p "{{unified_linked_dpath}}"
    #    just -f link_md/justfile run "{{unified_unlinked_dpath}}" "{{unified_linked_dpath}}"
    #
    #    # Format/Lint the linked markdown files
    #    just _print_section "Unified: Formatting unified, linked files"
    #    just lint markdown "{{unified_linked_dpath}}"

assemble_unified:
    #!/usr/bin/env bash
    set -euo pipefail
    just _print_section "Unified: Copying markdown to destination repo (data-md)"
    dest_dir="{{steel_compendium_dpath}}/data-md"
    just _delete_dir_except_git "$dest_dir"
    cp -R "{{unified_linked_dpath}}"/* "$dest_dir"
    just _add_license "$dest_dir"
