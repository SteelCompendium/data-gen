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

gen input_fpath:
    #!/usr/bin/env bash
    set -euo pipefail
    just _wipe_dir "{{heroes_staging_dpath}}"
    just heroes gen_heroes_md_unlinked "{{input_fpath}}" "{{heroes_unlinked_dpath}}"
    # TODO - just link_md_files ..., then change to heroes_linked_dpath
    just _copy_data_to_repo "{{heroes_unlinked_dpath}}" "data-rules-md"

##################################################
# Private Recipes
##################################################

# After heroes book markdown is fully cleaned up, will generate all markdown files
[private]
gen_heroes_md_unlinked input_fpath output_dpath:
    #!/usr/bin/env bash
    set -euo pipefail

    just _print_section "Heroes: Generating hero markdown"
    mkdir -p "{{heroes_unlinked_dpath}}"

    # Abilities: Extract Table of Contents from heroes.md
    just _print_section "Heroes: Converting heroes markdown to Table of Contents"
    toc_fpath="{{heroes_staging_dpath}}/0_abilities/toc.md"
    mkdir -p "$(dirname "$toc_fpath")"
    just markdown extract_toc "{{input_fpath}}" "$toc_fpath"

    # Abilities: Convert ToC into abilities.yml config
    # (This is setup to be run as a separate step so that abilities.yml can be edited, but for now no edits are needed)
    just _print_section "Heroes: Converting ToC to abilities config yaml"
    ability_config_fpath="{{heroes_staging_dpath}}/0_abilities/abilities.yml"
    just abilities generate_config "$toc_fpath" "$ability_config_fpath"

    # Sections: Convert markdown to html
    just _print_section "Heroes: Converting MD to html"
    html_fpath="{{heroes_staging_dpath}}/1_html/Draw Steel Heroes.html"
    just markdown to_html "{{input_fpath}}" "$html_fpath"

    # Sections: extract out sections using html xpath
    just _print_section "Heroes: Extracting hero sections"
    html_sections_dpath="{{heroes_staging_dpath}}/2_html_sections"
    just extract_heroes_sections run "$html_fpath" "$html_sections_dpath"

    # Ability Sections: extract out ability sections using abilities.yml config
    just _print_section "Heroes: Extracting ability and feature sections from html"
    just abilities extract_sections "$ability_config_fpath" "$html_fpath" "$html_sections_dpath/Abilities"

    # Sections: Convert html sections to md sections
    just _print_section "Heroes: Converting html to md"
    md_sections_dpath="{{heroes_staging_dpath}}/3_md_sections"
    just html_to_md run "$html_sections_dpath" "$md_sections_dpath"

    # Abilities: Generate indexes for abilities (depth=1 so we index the "*-Level Features" dirs too)
    just abilities gen_index_for_each_dir_in "${md_sections_dpath}/Abilities" "1"

    # TODO - more frontmatter?  Ability index
    #    # Transform the markdown files in-place
    #    just -f frontmatter/justfile run "$md_sections_formatted_dpath"
    #
    #    # Build the ability index tables
    #    just -f generate_ability_index/justfile run "${md_sections_formatted_dpath}/Abilities"

    # Assemble all markdown together for final formatting, linking, etc
    preformatted_dpath="{{heroes_staging_dpath}}/8_preformatted"
    mkdir -p "$preformatted_dpath"
    cp -R "$md_sections_dpath"/* "$preformatted_dpath"
    just heroes input_md_cleanup "{{input_fpath}}" "${preformatted_dpath}/Draw Steel Heroes - Unlinked.md"

    # Format/Lint all markdown files
    formatted_dpath="{{heroes_staging_dpath}}/9_formatted"
    cp -R "$preformatted_dpath" "$formatted_dpath"
    just lint markdown "$formatted_dpath"

    # Finally, move to output dir
    cp -R "$formatted_dpath"/* "{{output_dpath}}/"

input_md_cleanup input_fpath output_fpath:
    #!/usr/bin/env bash
    set -euo pipefail
    cp "{{input_fpath}}" "{{output_fpath}}"
    just _print_section "Heroes: Cleaning up original heroes markdown file"

    # Add frontmatter
    tmp=$(mktemp)
    {
      echo '---'
      echo 'title: Draw Steel Heroes'
      echo '---'
      cat "{{output_fpath}}"
    } > "$tmp" && mv "$tmp" "{{output_fpath}}"

    # Replace H7 headers with bold+span
    echo >&2 "Replacing H7 headers"
    sed -i -E 's/^####### (.*)$/**<span class="steel-compendium-h7">\1<\/span>**/g' "{{output_fpath}}"

    # Replace H8 headers with bold+span
    echo >&2 "Replacing H8 headers"
    # TODO - consider adding `<a class="headerlink" id="scalar-assault-bold" href="scalar-assault-bold" title="Permanent link">&para;</a>`
    sed -i -E 's/^######## (.*)$/**<span class="steel-compendium-ability">\1<\/span>**/g' "{{output_fpath}}"

# Given a fully-generated directory of markdown, will auto-link files to itself
[private]
link_md_files:
    #!/usr/bin/env bash
    set -euo pipefail
    mkdir -p "{{heroes_linked_dpath}}"
#    # Link MD section files to each other
#    #just -f link_md/justfile run "$md_sections_formatted_dpath" "{{staging_heroes_linked_dpath}}"

[private]
assemble_heroes src_dpath:
    #!/usr/bin/env bash
    set -euo pipefail
    just _print_section "Heroes: Copying markdown to destination repo (data-rules-md)"
    dest_dir="$(just _steel_compendium_dpath)/data-rules-md"
    just _delete_dir_except_git "$dest_dir"
    cp -R "{{src_dpath}}"/* "$dest_dir"
    just _add_license "$dest_dir"
