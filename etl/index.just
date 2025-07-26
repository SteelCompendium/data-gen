# Justfile module expected to be named "index"

##################################################
# Constants and env vars
##################################################

##################################################
# Public Recipes
##################################################

export BASH_ENV := ".utils/.utilsrc"
set shell := ["bash", "-c"]

# Generates a markdown index file that contains a table of all markdown files in `to_index_dpath`
# Table includes a column for each item specified in `space_separated_columns` (special case: `file_name`)
gen to_index_dpath output_fpath space_separated_columns="file_name" title="":
    #!/usr/bin/env bash
    set -euo pipefail

    echo >&2 "    Index generation: '{{to_index_dpath}}'"
    echo >&2 "    Index file: '{{output_fpath}}'"
    if [ ! -d "{{to_index_dpath}}" ]; then
        echo >&2 "    [WARNING] Cannot generate index: missing parent dpath '{{to_index_dpath}}'"
        exit
    fi

    dir="{{to_index_dpath}}"
    out="{{output_fpath}}"

    # split columns into an array
    read -r -a cols <<< "{{space_separated_columns}}"

    {
      # ─── pre-table content ──────────────────────────────────────────────────
        echo "---"
        echo "type: index"
        echo "---"
        echo

        if [ "{{title}}" == "" ]; then
            title="{{titlecase(file_stem(output_fpath))}}"
        else
            title="{{title}}"
        fi
        echo "# $title Index"
        echo

      # ─── header ─────────────────────────────────────────────────────────────
      printf '|'
      for c in "${cols[@]}"; do
        printf " %s |" "$c"
      done
      printf '\n|'
      for _ in "${cols[@]}"; do
        printf ' --- |'
      done
      printf '\n'

      # ─── rows ────────────────────────────────────────────────────────────────
      shopt -s globstar

      for f in "$dir"/**/*.md; do
        # make sure it actually matched something
        [[ -e $f ]] || continue
        # skip index files
        [[ "$(just index _get_frontmatter_value "type" "$f")" != "index" ]] || continue
        echo >&2 "        $f"

        printf '|'
        for c in "${cols[@]}"; do
          if [[ $c == file_name ]]; then
              # For now we are going to leave these as the file name and assume the auto-linker will take care of it
            file_name=$(basename "$f")
            name="${file_name%.*}"
            val="$name"
            #val="[${name}]('${file_name}')"
          else
            # grab `.key` from the front-matter, defaulting to "" if missing
            val=$(just index _get_frontmatter_value "$c" "$f")
          fi

          # escape any pipes
          val=${val//|/\\|}
          printf " %s |" "$val"
        done
        printf '\n'
      done
    } > "$out"
    echo >&2

##################################################
# Private Recipes
##################################################

_get_frontmatter_value key md_fpath:
    #!/usr/bin/env bash
    set -euo pipefail
    yq e --front-matter=markdown \
        --exit-status \
        --null-input=false \
        ".{{key}} // \"\"" \
        "{{md_fpath}}"