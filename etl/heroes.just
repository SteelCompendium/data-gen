# Justfile module expected to be named "heroes"

##################################################
# Constants and env vars
##################################################

heroes_staging_dpath := `just _staging_dpath` / "heroes"

##################################################
# Public Recipes
##################################################

export BASH_ENV := ".utils/.utilsrc"
set shell := ["bash", "-c"]

clean_and_prep:
    #!/usr/bin/env bash
    set -euo pipefail
    mkdir -p "{{heroes_staging_dpath}}"
    rm -rf "{{heroes_staging_dpath}}/*"

gen input_fpath: clean_and_prep
    #!/usr/bin/env bash
    set -euo pipefail
    just heroes gen_heroes_md "{{input_fpath}}"
    just heroes assemble_heroes

# After heroes book markdown is fully cleaned up, will parse the document into final form
gen_heroes_md input_fpath:
    #!/usr/bin/env bash
    set -euo pipefail
    
    # Convert markdown to html
    html_fpath="{{heroes_staging_dpath}}/html/Draw Steel Heroes.html"
    just md_to_html run "{{input_fpath}}" "$html_fpath"
#
#    # extract out sections using html xpath
#    html_sections_dpath="{{heroes_staging_dpath}}/html_sections"
#    just -f extract_html_sections/heroes/justfile run "$html_fpath" "$html_sections_dpath"
#
#    # Convert html sections to md sections
#    md_sections_dpath="{{heroes_staging_dpath}}/md_sections"
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
#    cp "{{heroes_markdown_source_path}}" "$md_sections_formatted_dpath"
#
#    # Link MD section files to each other
#    #just -f link_md/justfile run "$md_sections_formatted_dpath" "{{staging_heroes_linked_dpath}}"
#
#    # Format/Lint the linked markdown files
#    just -f mdformat/justfile run "{{staging_heroes_linked_dpath}}"
#    # TODO - I should format the unlinked files?

assemble_heroes:
    #!/usr/bin/env bash
    set -euo pipefail
    echo >&2 "--- Assembling heroes --- "
    # TODO
#    dest_dir="$(just _steel_compendium_dpath)/data-heroes-md"
#    just _delete_dir_except_git "$dest_dir"
#    cp -R "{{staging_heroes_linked_dpath}}"/* "$dest_dir"
#    cp "{{heroes_markdown_source_path}}" "${dest_dir}/Draw Steel heroes (original).md"
#    just _add_license "$dest_dir"
