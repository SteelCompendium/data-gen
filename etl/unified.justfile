# Global dirs
data_gen_root_dpath := justfile_directory() / ".."
data_root_dpath := data_gen_root_dpath / ".."

# Input/source files
rules_md_source_dpath := data_root_dpath / "data-rules-md"
bestiary_md_source_dpath := data_root_dpath / "data-bestiary-md"
# TODO - change this to data-adventures-md when its made, this is fragile as heck
adventures_md_source_dpath := data_root_dpath / "staging" / "adventures" / "md_sections_formatted_linked"

# Staging dirs
staging_dpath := data_root_dpath / "staging"
staging_unified_dpath := staging_dpath / "unified"
staging_unified_linked_dpath := staging_unified_dpath / "md_sections_formatted_linked"

clean_and_prep:
    #!/usr/bin/env bash
    set -euo pipefail
    if [ -d "{{staging_unified_dpath}}" ]; then
        rm -rf "{{staging_unified_dpath}}"
    fi
    mkdir -p "{{staging_unified_dpath}}"

gen_unified: clean_and_prep
    #!/usr/bin/env bash
    set -euo pipefail
    just -f {{justfile()}} gen_unified_md
    just -f {{justfile()}} assemble_unified

gen_unified_md:
    #!/usr/bin/env bash
    set -euo pipefail

    md_formatted_dpath="{{staging_unified_dpath}}/md_formatted"
    mkdir -p "$md_formatted_dpath"

    # Add the original MD files to the output so it can be linked and formatted
    # Using rsync to avoid .git dir
    rsync -a "{{rules_md_source_dpath}}"/* "${md_formatted_dpath}/" --exclude '.git'
    rsync -a "{{bestiary_md_source_dpath}}"/* "${md_formatted_dpath}/Bestiary" --exclude '.git'
    rsync -a "{{adventures_md_source_dpath}}"/* "${md_formatted_dpath}" --exclude '.git'

    # Link MD section files to each other
    just -f link_md/justfile run "$md_formatted_dpath" "{{staging_unified_linked_dpath}}"

    # Format/Lint the linked markdown files
    just -f mdformat/justfile run "{{staging_unified_linked_dpath}}"
    # TODO - I should format the unlinked files?

assemble_unified:
    #!/usr/bin/env bash
    set -euo pipefail
    echo >&2 "--- Assembling Unified --- "
    dest_dir="{{data_root_dpath}}/data-md"
    just _delete_dir_except_git "$dest_dir"
    cp -R "{{staging_unified_linked_dpath}}"/* "$dest_dir"
