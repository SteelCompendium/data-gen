# Justfile module expected to be named "monsters"

##################################################
# Constants and env vars
##################################################

steel_compendium_dpath := `just _steel_compendium_dpath`
input_dpath := `just _input_dpath`
monsters_staging_dpath := `just _staging_dpath` / "Monsters Book"
monsters_unlinked_dpath := monsters_staging_dpath / "unlinked"
monsters_linked_dpath := monsters_staging_dpath / "linked"

##################################################
# Public Recipes
##################################################

export BASH_ENV := ".utils/.utilsrc"
set shell := ["bash", "-c"]

gen input_fpath:
    #!/usr/bin/env bash
    set -euo pipefail
    just _wipe_dir "{{monsters_staging_dpath}}"
    mkdir -p "{{monsters_unlinked_dpath}}"

    just monsters gen_monsters_md_unlinked "{{input_fpath}}" "{{monsters_unlinked_dpath}}"
    # TODO - just link_md_files ..., then change to monsters_linked_dpath
    just monsters convert_md_to_other_formats "{{monsters_unlinked_dpath}}"

##################################################
# Private Recipes
##################################################

# After monsters book markdown is fully cleaned up, will generate all markdown files
[private]
gen_monsters_md_unlinked input_fpath output_dpath:
    #!/usr/bin/env bash
    set -euo pipefail

    just _print_section "Monsters: Generating monster markdown"
    mkdir -p "{{monsters_unlinked_dpath}}"

    # Sections: Convert markdown to html
    just _print_section "Monsters: Converting MD to html"
    html_fpath="{{monsters_staging_dpath}}/1_html/Draw Steel Monsters.html"
    just markdown to_html "{{input_fpath}}" "$html_fpath"

    # Sections: extract out sections using html xpath
    just _print_section "Monsters: Extracting monster sections"
    html_sections_dpath="{{monsters_staging_dpath}}/2_html_sections"
    just monsters_sections extract "$html_fpath" "$html_sections_dpath"

    # Sections: Convert html sections to md sections
    just _print_section "Monsters: Converting html to md"
    md_sections_dpath="{{monsters_staging_dpath}}/3_md_sections"
    just html to_md "$html_sections_dpath" "$md_sections_dpath"

    # Sections: generate frontmatter and classification
    just _print_section "Monsters: Generating metadata (frontmatter)"
    # TODO - avoid generating classification.json until source material (md) is final
    rm -f "{{input_dpath}}/classification.json"
    # TODO - merge these three?
    just sc_classification gen_frontmatter "${md_sections_dpath}" "{{input_dpath}}/classification.json"
    just monsters_frontmatter generate "${md_sections_dpath}"
    just frontmatter process_all "${md_sections_dpath}"

    # Sections: Generate indexes
    just monsters_sections gen_indexes "${md_sections_dpath}"

    # Assemble all markdown together for final formatting, linking, etc
    preformatted_dpath="{{monsters_staging_dpath}}/7_preformatted"
    mkdir -p "$preformatted_dpath"
    cp -R "$md_sections_dpath"/* "$preformatted_dpath"
    just monsters input_md_cleanup "{{input_fpath}}" "${preformatted_dpath}/Draw Steel Monsters - Unlinked.md"

    # Format/Lint all markdown files
    formatted_dpath="{{monsters_staging_dpath}}/8_formatted_md"
    cp -R "$preformatted_dpath" "$formatted_dpath"
    just markdown lint "$formatted_dpath"

    # Finally, move to output dir
    cp -R "$formatted_dpath"/* "{{output_dpath}}/"

# Cleans up the original "Draw Steel Monsters.md" file for inclusion in data-md repo
input_md_cleanup input_fpath output_fpath:
    #!/usr/bin/env bash
    set -euo pipefail
    cp "{{input_fpath}}" "{{output_fpath}}"
    just _print_section "Monsters: Cleaning up original monsters markdown file"

    # Add frontmatter
    tmp=$(mktemp)
    {
      echo '---'
      echo 'title: Draw Steel Monsters Book'
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
    mkdir -p "{{monsters_linked_dpath}}"
#    # Link MD section files to each other
#    #just -f link_md/justfile run "$md_sections_formatted_dpath" "{{staging_monsters_linked_dpath}}"

# Given a directory of (formatted) markdown files, converts them into json, yaml, etc
convert_md_to_other_formats md_dpath:
    #!/usr/bin/env bash
    set -euo pipefail

    just _print_section "Monsters: Converting markdown into other formats"
    conversions_dpath="{{monsters_staging_dpath}}/9_conversions"

    # Convert Statblocks
    find "{{md_dpath}}/Monsters" -type d -name "Statblocks" | while read -r statblock_dpath; do
        # note: monster_type might be "rivals/1st-echelon"
        monster_type="$(just monsters trim_path "{{md_dpath}}/Monsters/" "/Statblocks" "$statblock_dpath")"
        echo "Converting Statblocks for $monster_type"
        just statblocks convert_all "${statblock_dpath}" "json" "${conversions_dpath}/json/Monsters/${monster_type}/Statblocks"
        just statblocks convert_all "${statblock_dpath}" "yaml" "${conversions_dpath}/yaml/Monsters/${monster_type}/Statblocks"
    done

    # Convert Monster Featureblocks
    find "{{md_dpath}}/Monsters" -type d -name "Features" | while read -r featureblock_dpath; do
        # note: monster_type might be "rivals/1st-echelon"
        monster_type="$(just monsters trim_path "{{md_dpath}}/Monsters/" "/Features" "$featureblock_dpath")"
        echo "Converting Featureblocks for $monster_type"
        just featureblocks convert_all "${featureblock_dpath}" "json" "${conversions_dpath}/json/Monsters/${monster_type}/Features"
        just featureblocks convert_all "${featureblock_dpath}" "yaml" "${conversions_dpath}/yaml/Monsters/${monster_type}/Features"
    done

    # Convert Dynamic Terrain
    find "{{md_dpath}}/Dynamic Terrain" -type d | while read -r dt_dpath; do
        # Skip the Dynamic Terrain parent directory
        if [ "$(basename "$dt_dpath")" == "Dynamic Terrain" ]; then continue; fi
        dt_type="$(just monsters trim_path "{{md_dpath}}/Dynamic Terrain/" "" "$dt_dpath")"
        echo "Converting Featureblocks for $dt_type"
        just featureblocks convert_all "${dt_dpath}" "json" "${conversions_dpath}/json/Dynamic Terrain/${dt_type}"
        just featureblocks convert_all "${dt_dpath}" "yaml" "${conversions_dpath}/yaml/Dynamic Terrain/${dt_type}"
    done

    # Make the DSE markdown by embedding the yaml
    mkdir -p "${conversions_dpath}/md-dse"
    cp -R "{{md_dpath}}"/* "${conversions_dpath}/md-dse"
    just markdown embed_yaml "ds-statblock" "${conversions_dpath}/md-dse/Monsters" "Statblocks/" "${conversions_dpath}/yaml/Monsters"
    just markdown embed_yaml "ds-featureblock" "${conversions_dpath}/md-dse/Monsters" "Features/" "${conversions_dpath}/yaml/Monsters"
    just markdown embed_yaml "ds-featureblock" "${conversions_dpath}/md-dse/Dynamic Terrain" "" "${conversions_dpath}/yaml/Dynamic Terrain"

    # TODO - build an aggregate file of all the statblocks
    #just abilities gen_aggregate_data_doc "${conversions_dpath}/json/Abilities" "json" "${conversions_dpath}/json/Abilities/abilities.json"
    #just abilities gen_aggregate_data_doc "${conversions_dpath}/yaml/Abilities" "yaml" "${conversions_dpath}/yaml/Abilities/abilities.yaml"

    just _copy_data_to_repo "${conversions_dpath}/json" "data-bestiary-json"
    just _copy_data_to_repo "${conversions_dpath}/yaml" "data-bestiary-yaml"
    just _copy_data_to_repo "${conversions_dpath}/md-dse" "data-bestiary-md-dse"

    # Separate blockquotes with a <!-- --> to avoid merges
    # only separate blockquotes on the markdown variant
    just markdown separate_blockquotes "{{md_dpath}}"
    just _copy_data_to_repo "{{md_dpath}}" "data-bestiary-md" "/Monsters"

trim_path prefix suffix dpath:
    #!/usr/bin/env bash
    set -euo pipefail
    dpath="{{dpath}}"
    result="${dpath#{{prefix}}}"
    result="${result%{{suffix}}}"
    echo "$result"