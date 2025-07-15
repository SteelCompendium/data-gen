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
    just _copy_data_to_repo "{{adventures_unlinked_dpath}}" "data-adventures-md"

##################################################
# Private Recipes
##################################################
