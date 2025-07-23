log_prefix := "[JUST][html]"

# Converts all files in the folder from html to md
run html_src_dpath md_dest_dpath:
    #!/usr/bin/env bash
    set -euo pipefail
    echo >&2 "{{log_prefix}} --- Converting html sections to markdown --- "
    echo >&2 "    HTML source: '{{html_src_dpath}}'"
    echo >&2 "    MD dest: '{{md_dest_dpath}}'"

    html_src_dir="{{html_src_dpath}}"
    md_dest_dpath="{{md_dest_dpath}}"

    # Ensure source directory exists
    if [ ! -d "$html_src_dir" ]; then
        echo "Source directory does not exist: $html_src_dir"
        exit 1
    fi

    # Ensure destination directory exists
    mkdir -p "$md_dest_dpath"

    # Write the lua functions
    lua_filter_fpath="$(mktemp)"
    just html write_lua_to_file "$lua_filter_fpath"

    # Walk through all HTML files in the source directory
    find "$html_src_dir" -type f -name "*.html" | while read -r html_file; do
        # Compute relative path from source directory
        rel_path="${html_file#$html_src_dir/}"

        # Get the destination directory path
        dest_dir="$md_dest_dpath/$(dirname "$rel_path")"
        mkdir -p "$dest_dir"

        # Build filename
        src_filename="$(basename "$html_file")"
        markdown_filename=$(echo "$src_filename" | sed -e 's/\.html$/\.md/')

        # Convert HTML to Markdown with link adjustment
        pandoc --wrap=none --standalone \
            --from=html \
            --to=markdown_strict+pipe_tables+yaml_metadata_block \
            --lua-filter="$lua_filter_fpath" \
            -o "$dest_dir/$markdown_filename" \
            "$html_file"
    done
    rm -rf "$lua_filter_fpath"

#add_meta_all metadata_mapping_yml_fpath :
#    #!/usr/bin/env bash
#    set -euo pipefail
#    for htmlfile in "$tmpdir"/*; do
#        filename="$(basename "$htmlfile")"
#        # use basename sans extension as the 'name' meta
#        name="${filename%.*}"
#
#        for key in "${meta_fields[@]}"; do
#            val="${!key}"
#            if [[ -n "$val" ]]; then
#                just html add_metadata "$key" "$val" "$htmlfile" "$htmlfile"
#            fi
#        done
#
#
#        {
#            echo "<head>"
#            for key in "${meta_fields[@]}"; do
#                val="${!key}"
#                if [[ -n "$val" ]]; then
#                    printf '  <meta name="%s" content="%s" />\n' "$key" "$val"
#                fi
#            done
#            echo "</head>"
#            # TO
#            just abilities replace_p_heading_with_h6 "$(cat "$htmlfile")"
#        } > "$ability_output_dpath/$filename"
#    done

# Adds <meta> tag to html file.  Adds <head> if necessary
add_metadata key value input_fpath output_fpath:
    #!/usr/bin/env bash
    set -euo pipefail
    if grep -qi '<head[ >]' "{{input_fpath}}"; then
        # Insert the meta tag immediately after the first <head …> tag
        awk -v meta="  <meta name=\"{{key}}\" content=\"{{value}}\" />" '
            BEGIN { IGNORECASE=1 }
            head_done==0 && /<head([^>]*)>/ {
                print
                print meta
                head_done=1
                next
            }
            { print }
        ' "{{input_fpath}}" > "{{output_fpath}}"
    else
        {
            printf '<head>\n  <meta name="%s" content="%s" />\n</head>\n' "{{key}}" "{{value}}"
            cat "{{input_fpath}}"
        } > "{{output_fpath}}"
    fi


[private]
write_lua_to_file fpath:
    #!/usr/bin/env bash
    set -euo pipefail
    cat <<EOF > "{{fpath}}"
    function Link(el)
      -- Replace links ending with .html to .md
      el.target = el.target:gsub("%.html$", ".md")
      return el
    end
    EOF