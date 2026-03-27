# Shared utility variables and recipes imported by justfile and modules.
# Use `import '_utils.just'` -- do NOT use `mod` to avoid circular deps.

##################################################
# Shared Constants
##################################################

data_gen_root_dpath := justfile_directory() / ".."
steel_compendium_root_dpath := data_gen_root_dpath / ".."
staging_dpath := data_gen_root_dpath / "staging"
input_dpath := data_gen_root_dpath / "input"

##################################################
# Path Recipes
##################################################

# Prints the absolute path to the data-gen repo
[private]
_data_gen_dpath:
    #!/usr/bin/env bash
    set -euo pipefail
    realpath "{{data_gen_root_dpath}}"

# Prints the absolute path to the Steel Compendium parent directory
[private]
_steel_compendium_dpath:
    #!/usr/bin/env bash
    set -euo pipefail
    realpath "{{steel_compendium_root_dpath}}"

# Prints the absolute path to the staging directory
[private]
_staging_dpath:
    #!/usr/bin/env bash
    set -euo pipefail
    mkdir -p "{{staging_dpath}}"
    realpath "{{staging_dpath}}"

# Prints the absolute path to the input directory
[private]
_input_dpath:
    #!/usr/bin/env bash
    set -euo pipefail
    mkdir -p "{{input_dpath}}"
    realpath "{{input_dpath}}"

##################################################
# Display Recipes
##################################################

[private]
_print_title name:
    #!/usr/bin/env bash
    set -euo pipefail
    echo
    figlet '{{name}}'
    echo '===================================================================================================='
    echo

[private]
_print_header name:
    #!/usr/bin/env bash
    set -euo pipefail
    echo
    echo '{{name}}'
    echo '==========================================================================='
    echo

[private]
_print_section name:
    #!/usr/bin/env bash
    set -euo pipefail
    echo
    name="{{name}}"
    prefix="--- $name "
    prefix_len=$(printf '%s' "$prefix" | wc -m)
    pad_len=$(( 75 - prefix_len ))
    if (( pad_len < 0 )); then pad_len=0; fi
    pad=$(printf '%0.s-' $(seq 1 "$pad_len"))
    printf '%s\n\n' "${prefix}${pad}"

##################################################
# File/Directory Recipes
# TODO - all these should be moved to separate justfiles
##################################################

[private]
_wipe_all:
    just _wipe_dir "{{staging_dpath}}"

[private]
_wipe_dir dpath:
    #!/usr/bin/env bash
    set -euo pipefail
    just _print_section "Wiping directory '{{dpath}}'"
    if [ -d "{{dpath}}" ]; then
        rm -rf "{{dpath}}"
    fi
    mkdir -p "{{dpath}}"

# Wipes a Steel Compendium data-* repo, copies data (markdown, etc) from a given dir into it, then adds LICENSE
[private]
_copy_data_to_repo src_dpath sc_repo_name rel_dpath="":
    #!/usr/bin/env bash
    set -euo pipefail
    just _print_section "Copying data to destination repo ({{sc_repo_name}})"
    dest_dir="{{steel_compendium_root_dpath}}/{{sc_repo_name}}"
    just _delete_dir_except_git "$dest_dir"
    mkdir -p "${dest_dir}{{rel_dpath}}"
    cp -R "{{src_dpath}}"/* "${dest_dir}{{rel_dpath}}"
    just _add_license "$dest_dir"

# deletes all the (non-hidden) files in a directory
[private]
_delete_dir_except_git dir_to_delete:
    #!/usr/bin/env bash
    set -euo pipefail
    tempdir="$(mktemp -d)"
    echo "$tempdir"
    # add a dummy file to avoid crashing in case the dir is empty
    touch "{{dir_to_delete}}/dummy.txt"
    mv "{{dir_to_delete}}"/* "${tempdir}/"
    # by default dotglob will prevent hidden files from being included in * wildcard globs
    if [ -d "${tempdir}/.git" ]; then
        mv "${tempdir}/.git" "{{dir_to_delete}}"
    fi
    if [ -f "${tempdir}/README.md" ]; then
        mv "${tempdir}/README.md" "{{dir_to_delete}}"
    fi
    rm -rf "$tempdir"

# Adds the LICENSE file to a given directory
_add_license dpath:
    #!/usr/bin/env bash
    set -euo pipefail
    cd "{{dpath}}"
    # TODO - update this when final license is released
    echo "The Steel Compendium is an independent product published under the DRAW STEEL Creator License and is not affiliated with MCDM Productions, LLC. DRAW STEEL © 2024 MCDM Productions, LLC." > LICENSE
