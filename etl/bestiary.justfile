# Global dirs
data_gen_root_dpath := justfile_directory() / ".."
data_root_dpath := data_gen_root_dpath / ".."

# Input/source files
bestiary_markdown_source_path := data_gen_root_dpath / "Rules" / "Draw Steel Bestiary.md"

# Staging dirs
staging_dpath := data_root_dpath / "staging"
staging_bestiary_dpath := staging_dpath / "bestiary"
staging_bestiary_linked_dpath := staging_bestiary_dpath / "md_sections_formatted_linked"

clean_and_prep:
    #!/usr/bin/env bash
    set -euo pipefail
    if [ -d "{{staging_bestiary_dpath}}" ]; then
        rm -rf "{{staging_bestiary_dpath}}"
    fi
    mkdir -p "{{staging_bestiary_dpath}}"

gen_bestiary: clean_and_prep
    #!/usr/bin/env bash
    set -euo pipefail
    just -f {{justfile()}} gen_bestiary_md
    just -f {{justfile()}} assemble_bestiary

gen_bestiary_md:
    #!/usr/bin/env bash
    set -euo pipefail

    # Convert OG markdown to html
    html_fpath="{{staging_bestiary_dpath}}/html/Draw Steel Bestiary.html"
    just -f md_to_html/justfile run "{{bestiary_markdown_source_path}}" "$html_fpath"

    # extract out sections using html xpath
    html_sections_dpath="{{staging_bestiary_dpath}}/html_sections"
    just -f extract_html_sections/bestiary/justfile run "$html_fpath" "$html_sections_dpath"

    # Convert html sections to md sections
    md_sections_dpath="{{staging_bestiary_dpath}}/md_sections"
    just -f html_sections_to_md/justfile run "$html_sections_dpath" "$md_sections_dpath"

    # Transform the MD section files to make them usable
    md_sections_formatted_dpath="{{staging_bestiary_dpath}}/md_sections_formatted"
    mkdir -p "$md_sections_formatted_dpath"
    cp -R "$md_sections_dpath"/* "$md_sections_formatted_dpath"

    # Transform the markdown files in-place
    just -f convert_md_headers_title_case/justfile run "$md_sections_formatted_dpath"
    just -f reduce_header_levels/justfile run "$md_sections_formatted_dpath"
    just -f frontmatter/justfile run "$md_sections_formatted_dpath"
    just -f convert_ktdt_tables/justfile run "$md_sections_formatted_dpath"

    # Extract statblocks
    # TODO - statblocks dir hierarchy needs overhaul?
    just -f extract_statblocks/justfile run "{{bestiary_markdown_source_path}}" "$md_sections_formatted_dpath"

    # Note: from here on out we are ignoring the `.../md` dir since its crap.  Converting the yaml is better

    # Convert yaml statblocks to markdown
    just -f yaml_statblock_to_md/justfile run "${md_sections_formatted_dpath}/yaml" "${md_sections_formatted_dpath}/yaml-md"

    # Add the original bestiary MD file to the output so it can be linked and formatted
    # TODO - I would like this to go through the formatting steps
    cp "{{bestiary_markdown_source_path}}" "$md_sections_formatted_dpath"

    # Link MD section files to each other
    just -f link_md/justfile run "$md_sections_formatted_dpath" "{{staging_bestiary_linked_dpath}}"

    # Format/Lint the linked markdown files
    just -f mdformat/justfile run "{{staging_bestiary_linked_dpath}}"
    # TODO - I should format the unlinked files?

assemble_bestiary:
    #!/usr/bin/env bash
    set -euo pipefail
    echo >&2 "--- Assembling Bestiary --- "
    dest_md_dir="{{data_root_dpath}}/data-bestiary-md"
    just _delete_dir_except_git "$dest_md_dir"
    cp -R "{{staging_bestiary_linked_dpath}}"/yaml-md/* "$dest_md_dir"
    cp -R "{{staging_bestiary_linked_dpath}}"/*.md "$dest_md_dir"
    cp "{{bestiary_markdown_source_path}}" "${dest_md_dir}/Draw Steel Bestiary (original).md"

    dest_md_dse_dir="{{data_root_dpath}}/data-bestiary-md-dse"
    just _delete_dir_except_git "$dest_md_dse_dir"
    cp -R "{{staging_bestiary_linked_dpath}}"/md-dse/* "$dest_md_dse_dir"
    cp -R "{{staging_bestiary_linked_dpath}}"/*.md "$dest_md_dse_dir"
    cp "{{bestiary_markdown_source_path}}" "${dest_md_dse_dir}/Draw Steel Bestiary (original).md"

    dest_yaml_dir="{{data_root_dpath}}/data-bestiary-yaml"
    just _delete_dir_except_git "$dest_yaml_dir"
    cp -R "{{staging_bestiary_linked_dpath}}"/yaml/* "$dest_yaml_dir"
