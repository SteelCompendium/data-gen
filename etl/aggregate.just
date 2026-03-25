# Justfile module expected to be named "aggregate"

##################################################
# Constants and env vars
##################################################

##################################################
# Public Recipes
##################################################

# Generates a single file containing all feature data
gen_aggregate_data_doc root_field data_dpath data_format output_fpath:
    #!/usr/bin/env bash
    set -euo pipefail
    just _print_section "Generating aggregate file for '{{data_format}}' ('{{data_dpath}}')"
    aggregate_fpath=$(mktemp)

    # header
    if [ "{{data_format}}" == "json" ]; then
        echo '{ "{{root_field}}": [' > "$aggregate_fpath"
    elif [ "{{data_format}}" == "yaml" ]; then
        echo '{{root_field}}: ' > "$aggregate_fpath"
    fi

    data_dpath="{{data_dpath}}"

    # Extract root before first *
    root="${data_dpath%%\**}"
    root="${root%/}"

    # Fallback if no *
    if [ "$root" = "$data_dpath" ]; then
        root="$data_dpath"
    fi

    find "$root" -type f -path "$data_dpath/*.{{data_format}}" | while read -r fpath; do
        if [ "{{data_format}}" == "json" ]; then
            # prefix each line with two spaces, and add a comma to the end of the last line
            sed -e 's/^/  /' -e '$ s/$/,/' "$fpath" >> "$aggregate_fpath"
        elif [ "{{data_format}}" == "yaml" ]; then
            # First line gets "  - ", subsequent lines get 4 spaces
            sed -e '1s/^/  - /' -e '1!s/^/    /' "$fpath" >> "$aggregate_fpath"
        fi
    done

    # footer
    if [ "{{data_format}}" == "json" ]; then
        sed -i '${s/,$//}' "$aggregate_fpath"
        echo "]" >> "$aggregate_fpath"
        echo "}" >> "$aggregate_fpath"
    elif [ "{{data_format}}" == "yaml" ]; then
        echo "" >> "$aggregate_fpath"
    fi
    mv "$aggregate_fpath" "{{output_fpath}}"