# Justfile module expected to be named "monsters"

##################################################
# Constants and env vars
##################################################

monsters_staging_dpath := `just _staging_dpath` / "monsters"
monsters_unlinked_dpath := monsters_staging_dpath / "unlinked"
monsters_linked_dpath := monsters_staging_dpath / "linked"

##################################################
# Public Recipes
##################################################

export BASH_ENV := ".utils/.utilsrc"
set shell := ["bash", "-c"]

gen input_fpath:
    #!/usr/bin/env bash
    set -euo pipefail
    just _wipe_dir "{{monsters_staging_dpath}}"
    # TODO - actually implement this
    mkdir -p "{{monsters_unlinked_dpath}}"
    echo "Monster book has not yet been converted. Sorry for the inconvenience." > "{{monsters_unlinked_dpath}}/monsters.md"

    # TODO - I think I want to break up this repo into books to prepare for supplemental materials (so data-bestiary-md/monsters)
    just _copy_data_to_repo "{{monsters_unlinked_dpath}}" "data-bestiary-md"
    just _copy_data_to_repo "{{monsters_unlinked_dpath}}" "data-bestiary-md-dse"
    just _copy_data_to_repo "{{monsters_unlinked_dpath}}" "data-bestiary-json"
    just _copy_data_to_repo "{{monsters_unlinked_dpath}}" "data-bestiary-yaml"

##################################################
# Private Recipes
##################################################
