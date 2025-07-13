# Global dirs
data_gen_root_dpath := justfile_directory() / ".."
data_root_dpath := data_gen_root_dpath / ".."

# Staging dirs
staging_dpath := data_root_dpath / "staging"
staging_rules_dpath := staging_dpath / "rules"
staging_rules_linked_dpath := staging_rules_dpath / "md_sections_formatted_linked"

# Input/source files
rules_pdf_source_fpath := data_gen_root_dpath / "Rules" / "MCDM RPG Heroes Manuscript Pactreon Packet 4.pdf"
rules_markdown_source_path := staging_dpath / "Draw Steel Rules.md"

clean_and_prep:
    #!/usr/bin/env bash
    set -euo pipefail
    if [ -d "{{staging_rules_dpath}}" ]; then
        rm -rf "{{staging_rules_dpath}}"
    fi
    mkdir -p "{{staging_rules_dpath}}"

gen_rules: clean_and_prep
    #!/usr/bin/env bash
    set -euo pipefail
    just -f {{justfile()}} gen_rules_md
    just -f {{justfile()}} assemble_rules

gen_rules_md:
    #!/usr/bin/env bash
    set -euo pipefail
    
    # Convert markdown to html
    html_fpath="{{staging_rules_dpath}}/html/Draw Steel Rules.html"
    just -f md_to_html/justfile run "{{staging_dpath}}/Draw Steel Rules.md" "$html_fpath"

    # extract out sections using html xpath
    html_sections_dpath="{{staging_rules_dpath}}/html_sections"
    just -f extract_html_sections/rules/justfile run "$html_fpath" "$html_sections_dpath"

    # Convert html sections to md sections
    md_sections_dpath="{{staging_rules_dpath}}/md_sections"
    just -f html_sections_to_md/justfile run "$html_sections_dpath" "$md_sections_dpath"

    # Transform the MD section files to make them usable
    md_sections_formatted_dpath="{{staging_rules_dpath}}/md_sections_formatted"
    mkdir -p "$md_sections_formatted_dpath"
    cp -R "$md_sections_dpath"/* "$md_sections_formatted_dpath"

    # Transform the markdown files in-place
    just -f frontmatter/justfile run "$md_sections_formatted_dpath"
    
    # Build the ability index tables
    just -f generate_ability_index/justfile run "${md_sections_formatted_dpath}/Abilities"

    # Add the original rules MD file to the output so it can be linked and formatted
    # TODO - I would like this to go through the formatting steps, but it crashes on frontmatter gen
    cp "{{rules_markdown_source_path}}" "$md_sections_formatted_dpath"

    # Link MD section files to each other
    #just -f link_md/justfile run "$md_sections_formatted_dpath" "{{staging_rules_linked_dpath}}"

    # Format/Lint the linked markdown files
    just -f mdformat/justfile run "{{staging_rules_linked_dpath}}"
    # TODO - I should format the unlinked files?

assemble_rules:
    #!/usr/bin/env bash
    set -euo pipefail
    echo >&2 "--- Assembling Rules --- "
    dest_dir="{{data_root_dpath}}/data-rules-md"
    just _delete_dir_except_git "$dest_dir"
    cp -R "{{staging_rules_linked_dpath}}"/* "$dest_dir"
    cp "{{rules_markdown_source_path}}" "${dest_dir}/Draw Steel Rules (original).md"
    just _add_license "$dest_dir"
