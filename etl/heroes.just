# Justfile module expected to be named "heroes"

##################################################
# Constants and env vars
##################################################

steel_compendium_dpath := `just _steel_compendium_dpath`
input_dpath := `just _input_dpath`
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
    just heroes convert_md_to_other_formats "{{heroes_unlinked_dpath}}"

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
    just ability_config generate_config "$toc_fpath" "$ability_config_fpath"

    # Sections: Convert markdown to html
    just _print_section "Heroes: Converting MD to html"
    html_fpath="{{heroes_staging_dpath}}/1_html/Draw Steel Heroes.html"
    just markdown to_html "{{input_fpath}}" "$html_fpath"

    # Sections: extract out sections using html xpath
    just _print_section "Heroes: Extracting hero sections"
    html_sections_dpath="{{heroes_staging_dpath}}/2_html_sections"
    just heroes_sections extract "$html_fpath" "$html_sections_dpath"

    # Ability Sections: extract out ability sections using abilities.yml config
    just _print_section "Heroes: Extracting ability and feature sections from html"
    just extract_html_sections extract_sections "$ability_config_fpath" "$html_fpath" "$html_sections_dpath/Abilities" "skip_delete"

    # Sections: Convert html sections to md sections
    just _print_section "Heroes: Converting html to md"
    md_sections_dpath="{{heroes_staging_dpath}}/3_md_sections"
    just html to_md "$html_sections_dpath" "$md_sections_dpath"

    # Sections: generate frontmatter and classification
    just _print_section "Heroes: Generating metadata (frontmatter)"
    # TODO - avoid generating classification.json until source material (md) is final
    rm -f "{{input_dpath}}/classification.json"
    # TODO - merge these three?
    just sc_classification gen_frontmatter "${md_sections_dpath}" "{{input_dpath}}/classification.json"
    just heroes_frontmatter generate "${md_sections_dpath}"
    just frontmatter process_all "${md_sections_dpath}"

    # Abilities: Generate indexes for abilities (depth=1 so we index the "*-Level Features" dirs too)
    just abilities gen_index_for_each_dir_in "${md_sections_dpath}/Abilities" "1"
    # Sections: Generate indexes
    just heroes_sections gen_indexes "${md_sections_dpath}"

    # Assemble all markdown together for final formatting, linking, etc
    preformatted_dpath="{{heroes_staging_dpath}}/7_preformatted"
    mkdir -p "$preformatted_dpath"
    cp -R "$md_sections_dpath"/* "$preformatted_dpath"
    just heroes input_md_cleanup "{{input_fpath}}" "${preformatted_dpath}/Draw Steel Heroes - Unlinked.md"

    # Format/Lint all markdown files
    formatted_dpath="{{heroes_staging_dpath}}/8_formatted_md"
    cp -R "$preformatted_dpath" "$formatted_dpath"
    just markdown lint "$formatted_dpath"

    # Finally, move to output dir
    cp -R "$formatted_dpath"/* "{{output_dpath}}/"

# Cleans up the original "Draw Steel Heroes.md" file for inclusion in data-md repo
input_md_cleanup input_fpath output_fpath:
    #!/usr/bin/env bash
    set -euo pipefail
    cp "{{input_fpath}}" "{{output_fpath}}"
    just _print_section "Heroes: Cleaning up original heroes markdown file"

    # Add frontmatter
    tmp=$(mktemp)
    {
      echo '---'
      echo 'title: Draw Steel Heroes Book'
      echo '---'
      cat "{{output_fpath}}"
    } > "$tmp" && mv "$tmp" "{{output_fpath}}"

    # Replace H7 headers with bold+span
    echo >&2 "Replacing H7 headers"
    sed -i -E 's/^####### (.*)$/**<span class="steel-compendium-statblock">\1<\/span>**/g' "{{output_fpath}}"

    # Replace H8 headers with bold+span
    echo >&2 "Replacing H8 headers"
    # TODO - consider adding `<a class="headerlink" id="scalar-assault-bold" href="scalar-assault-bold" title="Permanent link">&para;</a>`
    sed -i -E 's/^######## (.*)$/**<span class="steel-compendium-ability">\1<\/span>**/g' "{{output_fpath}}"

    # Replace H8 headers with bold+span
    echo >&2 "Replacing H9 headers"
    sed -i -E 's/^######### (.*)$/**<span class="steel-compendium-malice">\1<\/span>**/g' "{{output_fpath}}"

# Given a fully-generated directory of markdown, will auto-link files to itself
[private]
link_md_files:
    #!/usr/bin/env bash
    set -euo pipefail
    mkdir -p "{{heroes_linked_dpath}}"
#    # Link MD section files to each other
#    #just -f link_md/justfile run "$md_sections_formatted_dpath" "{{staging_heroes_linked_dpath}}"

# Given a directory of (formatted) markdown files, converts them into json, yaml, etc
convert_md_to_other_formats md_dpath:
    #!/usr/bin/env bash
    set -euo pipefail

    just _print_section "Heroes: Converting markdown into other formats"
    conversions_dpath="{{heroes_staging_dpath}}/9_conversions"

    just abilities convert_all "{{md_dpath}}/Abilities" "json" "${conversions_dpath}/json/Abilities"
    just abilities convert_all "{{md_dpath}}/Abilities" "yaml" "${conversions_dpath}/yaml/Abilities"
    just abilities convert_all "{{md_dpath}}/Abilities" "xml" "${conversions_dpath}/xml/Abilities"
    # Dont convert to markdown: you will lose frontmatter data

    just abilities gen_aggregate_data_doc "${conversions_dpath}/json/Abilities" "json" "${conversions_dpath}/json/Abilities/abilities.json"
    just abilities gen_aggregate_data_doc "${conversions_dpath}/yaml/Abilities" "yaml" "${conversions_dpath}/yaml/Abilities/abilities.yaml"
    just abilities gen_aggregate_data_doc "${conversions_dpath}/xml/Abilities" "xml" "${conversions_dpath}/xml/Abilities/abilities.xml"

    just _copy_data_to_repo "${conversions_dpath}/json" "data-rules-json"
    just _copy_data_to_repo "${conversions_dpath}/yaml" "data-rules-yaml"
    just _copy_data_to_repo "${conversions_dpath}/xml" "data-rules-xml"

    # only separate blockquotes on the markdown variant
    just markdown separate_blockquotes "{{md_dpath}}"
    just _copy_data_to_repo "{{md_dpath}}" "data-rules-md"

