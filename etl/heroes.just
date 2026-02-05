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
    just heroes gen_heroes_md "{{input_fpath}}" "{{heroes_unlinked_dpath}}" "{{heroes_linked_dpath}}"
    just heroes convert_unlinked_md_to_other_formats "{{heroes_unlinked_dpath}}"
    just heroes convert_linked_md_to_other_formats "{{heroes_linked_dpath}}"

##################################################
# Private Recipes
##################################################

# After heroes book markdown is fully cleaned up, will generate all markdown files
[private]
gen_heroes_md input_fpath unlinked_output_dpath linked_output_dpath:
    #!/usr/bin/env bash
    set -euo pipefail

    just _print_section "Heroes: Generating hero markdown"
    mkdir -p "{{unlinked_output_dpath}}"
    mkdir -p "{{linked_output_dpath}}"

    # Features: Extract Table of Contents from heroes.md
    just _print_section "Heroes: Converting heroes markdown to Table of Contents"
    toc_fpath="{{heroes_staging_dpath}}/0_features/toc.md"
    mkdir -p "$(dirname "$toc_fpath")"
    just markdown extract_toc "{{input_fpath}}" "$toc_fpath"

    # Features: Convert ToC into features.yml config
    # (This is setup to be run as a separate step so that features.yml can be edited, but for now no edits are needed)
    just _print_section "Heroes: Converting ToC to features config yaml"
    feature_config_fpath="{{heroes_staging_dpath}}/0_features/features.yml"
    just features_config generate_config "$toc_fpath" "$feature_config_fpath"

    # Sections: Convert markdown to html
    just _print_section "Heroes: Converting MD to html"
    html_fpath="{{heroes_staging_dpath}}/1_html/Draw Steel Heroes.html"
    just markdown to_html "{{input_fpath}}" "$html_fpath"

    # Sections: extract out sections using html xpath
    just _print_section "Heroes: Extracting hero sections"
    html_sections_dpath="{{heroes_staging_dpath}}/2_html_sections"
    just heroes_sections extract "$html_fpath" "$html_sections_dpath"

    # Feature Sections: extract out feature sections using features.yml config
    just _print_section "Heroes: Extracting feature and feature sections from html"
    just extract_html_sections extract_sections "$feature_config_fpath" "$html_fpath" "$html_sections_dpath/Features" "skip_delete"

    # Sections: Convert html sections to md sections
    just _print_section "Heroes: Converting html to md"
    md_sections_dpath="{{heroes_staging_dpath}}/3_md_sections"
    just html to_md "$html_sections_dpath" "$md_sections_dpath"

    # Sections: generate frontmatter and classification
    just _print_section "Heroes: Generating metadata (frontmatter)"
    # TODO - avoid generating classification.json until source material (md) is final
    scc_to_path_json_fpath="$(just _staging_dpath)/scc_to_path.json"
    rm -f "{{input_dpath}}/classification.json"
    # TODO - merge these three?
    just sc_classification gen_frontmatter "${md_sections_dpath}" "{{input_dpath}}/classification.json" "$scc_to_path_json_fpath"
    just heroes_frontmatter generate "${md_sections_dpath}"
    just frontmatter process_all "${md_sections_dpath}"

    # Features: Generate indexes for features (depth=1 so we index the "*-Level Features" dirs too)
    just features gen_index_for_each_dir_in "${md_sections_dpath}/Features" "1"
    # Sections: Generate indexes
    just heroes_sections gen_indexes "${md_sections_dpath}"

    # Assemble all markdown together for final formatting, linking, etc
    preformatted_dpath="{{heroes_staging_dpath}}/7_preformatted"
    mkdir -p "$preformatted_dpath"
    cp -R "$md_sections_dpath"/* "$preformatted_dpath"
    just heroes input_md_cleanup "{{input_fpath}}" "${preformatted_dpath}/Draw Steel Heroes.md"

    # link
    linking_dpath="{{heroes_staging_dpath}}/8_linking_md"
    mkdir -p "$linking_dpath/unlinked"
    mkdir -p "$linking_dpath/linked"
    cp -R "$preformatted_dpath"/* "$linking_dpath/unlinked"
    cp -R "$preformatted_dpath"/* "$linking_dpath/linked"
    just linker remove_scc_links "$linking_dpath/unlinked"
    just linker apply_scc_links "$linking_dpath/linked" "$scc_to_path_json_fpath"

    # Format/Lint all markdown files
    formatted_dpath="{{heroes_staging_dpath}}/9_formatted_md"
    cp -R "$linking_dpath" "$formatted_dpath"
    just markdown lint "$formatted_dpath"

    # Keeping this for backwards compatability
    cp "${formatted_dpath}/unlinked/Draw Steel Heroes.md" "${formatted_dpath}/unlinked/Draw Steel Heroes - Unlinked.md"

    # Finally, move to output dir
    cp -R "$formatted_dpath/unlinked/"* "{{unlinked_output_dpath}}/"
    cp -R "$formatted_dpath/linked/"* "{{linked_output_dpath}}/"

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
    sed -i -E 's/^######## (.*)$/**<span class="steel-compendium-feature">\1<\/span>**/g' "{{output_fpath}}"

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
convert_unlinked_md_to_other_formats md_dpath:
    #!/usr/bin/env bash
    set -euo pipefail

    just _print_section "Heroes: Converting markdown into other formats"
    conversions_dpath="{{heroes_staging_dpath}}/10_conversions"

    just features convert_all "{{md_dpath}}/Features" "json" "${conversions_dpath}/json/Features"
    just features convert_all "{{md_dpath}}/Abilities" "json" "${conversions_dpath}/json/Abilities"
    just features convert_all "{{md_dpath}}/Features" "yaml" "${conversions_dpath}/yaml/Features"
    just features convert_all "{{md_dpath}}/Abilities" "yaml" "${conversions_dpath}/yaml/Abilities"
    # Dont convert to markdown: you will lose frontmatter data

    # Make the DSE markdown by embedding the yaml
    mkdir -p "${conversions_dpath}/md-dse"
    cp -R "{{md_dpath}}"/* "${conversions_dpath}/md-dse"
    just features embed_features "${conversions_dpath}/md-dse/Features" "${conversions_dpath}/yaml/Features"
    just features embed_features "${conversions_dpath}/md-dse/Abilities" "${conversions_dpath}/yaml/Abilities"

    # Build the aggregate data files
    just features gen_aggregate_data_doc "${conversions_dpath}/json/Features" "json" "${conversions_dpath}/json/Features/features.json"
    just features gen_aggregate_data_doc "${conversions_dpath}/json/Abilities" "json" "${conversions_dpath}/json/Features/abilities.json"
    just features gen_aggregate_data_doc "${conversions_dpath}/yaml/Features" "yaml" "${conversions_dpath}/yaml/Features/features.yaml"
    just features gen_aggregate_data_doc "${conversions_dpath}/yaml/Abilities" "yaml" "${conversions_dpath}/yaml/Features/abilities.yaml"

    just _copy_data_to_repo "${conversions_dpath}/json" "data-rules-json"
    just _copy_data_to_repo "${conversions_dpath}/yaml" "data-rules-yaml"

    # only separate blockquotes on the markdown variants
    just markdown separate_blockquotes "{{md_dpath}}"
    just _copy_data_to_repo "{{md_dpath}}" "data-rules-md"

    just markdown separate_blockquotes "${conversions_dpath}/md-dse"
    just _copy_data_to_repo "${conversions_dpath}/md-dse" "data-rules-md-dse"

# Given a directory of (linked and formatted) markdown files, converts them into json, yaml, etc
convert_linked_md_to_other_formats md_dpath:
    #!/usr/bin/env bash
    set -euo pipefail

    just _print_section "Heroes: Converting markdown into other formats"
    conversions_dpath="{{heroes_staging_dpath}}/10_conversions_linked"

    # generate the yaml for dse
    just features convert_all "{{md_dpath}}/Features" "yaml" "${conversions_dpath}/yaml/Features"
    just features convert_all "{{md_dpath}}/Abilities" "yaml" "${conversions_dpath}/yaml/Abilities"
    # Dont convert to markdown: you will lose frontmatter data

    # Make the DSE markdown by embedding the yaml
    mkdir -p "${conversions_dpath}/md-dse"
    cp -R "{{md_dpath}}"/* "${conversions_dpath}/md-dse"
    just features embed_features "${conversions_dpath}/md-dse/Features" "${conversions_dpath}/yaml/Features"
    just features embed_features "${conversions_dpath}/md-dse/Abilities" "${conversions_dpath}/yaml/Abilities"

    # only separate blockquotes on the markdown variants
    just markdown separate_blockquotes "{{md_dpath}}"
    just _copy_data_to_repo "{{md_dpath}}" "data-rules-md-linked"

    just markdown separate_blockquotes "${conversions_dpath}/md-dse"
    just _copy_data_to_repo "${conversions_dpath}/md-dse" "data-rules-md-dse-linked"

