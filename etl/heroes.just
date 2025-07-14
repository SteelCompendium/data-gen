# Justfile module expected to be named "heroes"

##################################################
# Constants and env vars
##################################################

heroes_staging_dpath := `just _staging_dpath` / "heroes"
heroes_unlinked_dpath := heroes_staging_dpath / "unlinked"
heroes_linked_dpath := heroes_staging_dpath / "linked"

##################################################
# Public Recipes
##################################################

export BASH_ENV := ".utils/.utilsrc"
set shell := ["bash", "-c"]

clean_and_prep:
    #!/usr/bin/env bash
    set -euo pipefail
    rm -rf "{{heroes_staging_dpath}}"
    mkdir -p "{{heroes_staging_dpath}}"

gen input_fpath: clean_and_prep
    #!/usr/bin/env bash
    set -euo pipefail
    just heroes gen_heroes_md_unlinked "{{input_fpath}}" "{{heroes_unlinked_dpath}}"
    just heroes assemble_heroes

# After heroes book markdown is fully cleaned up, will generate all markdown files
gen_heroes_md_unlinked input_fpath output_dpath:
    #!/usr/bin/env bash
    set -euo pipefail

    just _print_section "Generating hero markdown"
    mkdir -p "{{heroes_unlinked_dpath}}"

    # Convert markdown to html
    just _print_section "Converting MD to html"
    html_fpath="{{heroes_staging_dpath}}/1_html/Draw Steel Heroes.html"
    just md_to_html run "{{input_fpath}}" "$html_fpath"

    # extract out sections using html xpath
    just _print_section "Extracting hero sections"
    html_sections_dpath="{{heroes_staging_dpath}}/2_html_sections"
    just extract_heroes_sections run "$html_fpath" "$html_sections_dpath"

    #    # Convert html sections to md sections
    #    md_sections_dpath="{{heroes_staging_dpath}}/3_md_sections"
    #    just -f html_sections_to_md/justfile run "$html_sections_dpath" "$md_sections_dpath"
    #
    #    # Transform the MD section files to make them usable
    #    md_sections_formatted_dpath="{{heroes_staging_dpath}}/md_sections_formatted"
    #    mkdir -p "$md_sections_formatted_dpath"
    #    cp -R "$md_sections_dpath"/* "$md_sections_formatted_dpath"
    #
    #    # Transform the markdown files in-place
    #    just -f frontmatter/justfile run "$md_sections_formatted_dpath"
    #
    #    # Build the ability index tables
    #    just -f generate_ability_index/justfile run "${md_sections_formatted_dpath}/Abilities"
    #
    #    # Add the original heroes MD file to the output so it can be linked and formatted
    #    # TODO - I would like this to go through the formatting steps, but it crashes on frontmatter gen

    preformatted_dpath="{{heroes_staging_dpath}}/8_preformatted"
    mkdir -p "$preformatted_dpath"
    # Copy the original heroes markdown over to output dir
    cp "{{input_fpath}}" "${preformatted_dpath}/Draw Steel Heroes - Unlinked.md"

    # Format/Lint all markdown files
    formatted_dpath="{{heroes_staging_dpath}}/9_formatted"
    cp -R "$preformatted_dpath" "$formatted_dpath"
    just lint markdown "$formatted_dpath"

    # Finally, move to output dir
    cp -R "$formatted_dpath"/* "{{output_dpath}}/"

# Given a fully-generated directory of markdown, will auto-link files to itself
link_md_files:
    #!/usr/bin/env bash
    set -euo pipefail
    mkdir -p "{{heroes_linked_dpath}}"
#    # Link MD section files to each other
#    #just -f link_md/justfile run "$md_sections_formatted_dpath" "{{staging_heroes_linked_dpath}}"

assemble_heroes:
    #!/usr/bin/env bash
    set -euo pipefail
    just _print_section "Assembling heroes"
    # TODO
#    dest_dir="$(just _steel_compendium_dpath)/data-rules-md"
#    just _delete_dir_except_git "$dest_dir"
#    cp -R "{{staging_heroes_linked_dpath}}"/* "$dest_dir"
#    cp "{{heroes_markdown_source_path}}" "${dest_dir}/Draw Steel heroes (original).md"
#    just _add_license "$dest_dir"
