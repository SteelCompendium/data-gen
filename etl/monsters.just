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
    just monsters assemble_monsters "{{monsters_unlinked_dpath}}"

##################################################
# Private Recipes
##################################################

[private]
assemble_monsters src_dpath:
    #!/usr/bin/env bash
    set -euo pipefail
    just _print_section "Monsters: Copying markdown to destination repo (data-bestiary-md)"
    dest_dir="$(just _steel_compendium_dpath)/data-bestiary-md"
    just _delete_dir_except_git "$dest_dir"
    cp -R "{{src_dpath}}"/* "$dest_dir"
    just _add_license "$dest_dir"
