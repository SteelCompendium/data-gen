# Global dirs
data_gen_root_dpath := justfile_directory() / ".."
data_root_dpath := data_gen_root_dpath / ".."

# Input/source files
adventures_markdown_source_dpath := data_gen_root_dpath / "Adventures"

# Staging dirs
staging_dpath := data_root_dpath / "staging"
staging_adventures_dpath := staging_dpath / "adventures"
staging_adventures_linked_dpath := staging_adventures_dpath / "md_sections_formatted_linked"

clean_and_prep:
    #!/usr/bin/env bash
    set -euo pipefail
    if [ -d "{{staging_adventures_dpath}}" ]; then
        rm -rf "{{staging_adventures_dpath}}"
    fi
    mkdir -p "{{staging_adventures_dpath}}"

gen_adventures: clean_and_prep
    #!/usr/bin/env bash
    set -euo pipefail
    just -f {{justfile()}} gen_adventures_md
    just -f {{justfile()}} assemble_adventures

gen_adventures_md:
    #!/usr/bin/env bash
    set -euo pipefail

    md_formatted_dpath="{{staging_adventures_dpath}}/md_formatted"
    mkdir -p "$md_formatted_dpath"

    # Add the original adventures MD file to the output so it can be linked and formatted
    cp -R "{{adventures_markdown_source_dpath}}" "$md_formatted_dpath"

    # Link MD section files to each other
    just -f link_md/justfile run "$md_formatted_dpath" "{{staging_adventures_linked_dpath}}"

    # Format/Lint the linked markdown files
    just -f mdformat/justfile run "{{staging_adventures_linked_dpath}}"
    # TODO - I should format the unlinked files?

assemble_adventures:
    #!/usr/bin/env bash
    set -euo pipefail
    echo >&2 "--- Assembling Adventures --- "
    dest_dir="{{data_root_dpath}}/data-adventures-md"
    just _delete_dir_except_git "$dest_dir"
    cp -R "{{staging_adventures_linked_dpath}}"/* "$dest_dir"
    just _add_license "$dest_dir"
