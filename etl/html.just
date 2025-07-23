log_prefix := "[JUST][html]"

# Converts all files in the folder from html to md
to_md html_src_dpath md_dest_dpath:
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