# Justfile module expected to be named "adventures"

##################################################
# Constants and env vars
##################################################

adventures_staging_dpath := `just _staging_dpath` / "adventures"
adventures_unlinked_dpath := adventures_staging_dpath / "unlinked"
adventures_linked_dpath := adventures_staging_dpath / "linked"

##################################################
# Public Recipes
##################################################

export BASH_ENV := ".utils/.utilsrc"
set shell := ["bash", "-c"]

gen input_fpath:
    #!/usr/bin/env bash
    set -euo pipefail
    just _wipe_dir "{{adventures_staging_dpath}}"
    # TODO - actually implement this
    mkdir -p "{{adventures_unlinked_dpath}}"
    echo "Adventures have not yet been converted. Sorry for the inconvenience." > "{{adventures_unlinked_dpath}}/adventures.md"
    just adventures assemble_adventures "{{adventures_unlinked_dpath}}"

##################################################
# Private Recipes
##################################################

[private]
assemble_adventures src_dpath:
    #!/usr/bin/env bash
    set -euo pipefail
    just _print_section "Adventures: Copying markdown to destination repo (data-adventures-md)"
    dest_dir="$(just _steel_compendium_dpath)/data-adventures-md"
    just _delete_dir_except_git "$dest_dir"
    cp -R "{{src_dpath}}"/* "$dest_dir"
    just _add_license "$dest_dir"
