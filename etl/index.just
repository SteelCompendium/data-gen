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
# When `indent_nested` is non-empty, files in subdirectories are indented under their parent and sorted
# so that a parent file appears before its children (e.g. traits before subtraits).
gen to_index_dpath output_fpath space_separated_columns="file_name" title="" indent_nested="":
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

        if [ "{{title}}" == "" ]; then
            title="{{titlecase(file_stem(output_fpath))}}"
        else
            title="{{title}}"
        fi

        echo "---"
        echo "type: index"
        echo "title: '📑 Index'"
        echo "---"
        echo

        echo "# $title Index"
        echo

      # ─── header ─────────────────────────────────────────────────────────────
      printf '|'
      for c in "${cols[@]}"; do
        col_title=$(just index _titlecase "$c")
        printf " %s |" "$col_title"
      done
      printf '\n|'
      for _ in "${cols[@]}"; do
        printf ' --- |'
      done
      printf '\n'

      # ─── rows ────────────────────────────────────────────────────────────────
      shopt -s globstar nullglob

      # Build the sorted file list.
      # When indent_nested is set, sort so parent files appear before their children:
      #   Enchantment.md          (trait)
      #   Enchantment/Bar.md      (subtrait, indented)
      #   Essence.md              (trait)
      #   Essence/Baz.md          (subtrait, indented)
      if [[ -n "{{indent_nested}}" ]]; then
        # Build sort keys: for direct children use "Name/!", for nested use "Parent/Name"
        # The ! char sorts before letters, so the parent groups with and precedes its children.
        sorted_files=()
        while IFS= read -r -d '' f; do
          sorted_files+=("$f")
        done < <(
          for f in "$dir"/**/*.md; do
            base=${dir%/}
            relpath=${f#"$base"/}
            relpath_no_ext=${relpath%.md}
            # Count slashes to determine depth
            depth=$(echo "$relpath" | tr -cd '/' | wc -c)
            if (( depth == 0 )); then
              # Direct child: group key = its own name, sort second = ! (first in group)
              sort_key="${relpath_no_ext}/!"
            else
              # Nested child: group key = first path component, sort second = rest
              group="${relpath%%/*}"
              rest="${relpath_no_ext#*/}"
              sort_key="${group}/${rest}"
            fi
            printf '%s\t%s\0' "$sort_key" "$f"
          done | sort -z -t$'\t' -k1,1 | while IFS=$'\t' read -r -d '' _ fpath; do
            printf '%s\0' "$fpath"
          done
        )
      else
        sorted_files=()
        while IFS= read -r -d '' f; do
          sorted_files+=("$f")
        done < <(printf '%s\0' "$dir"/**/*.md | sort -z)
      fi

      for f in "${sorted_files[@]}"; do
        # make sure it actually matched something
        [[ -e $f ]] || continue
        # skip index files
        [[ "$(just index _get_frontmatter_value "type" "$f")" != "index" ]] || continue

        # Determine if this file is nested (in a subdirectory of the indexed dir)
        base=${dir%/}
        relpath=${f#"$base"/}
        depth=$(echo "$relpath" | tr -cd '/' | wc -c)
        is_nested=false
        if [[ -n "{{indent_nested}}" ]] && (( depth > 0 )); then
          is_nested=true
        fi

        printf '|'
        for c in "${cols[@]}"; do
          if [[ $c == file_name ]]; then
            file_name=$(basename "$f")
            name="${file_name%.*}"

            relpath_no_ext=${relpath%.md}

            # URL-encode each path component separately
            IFS='/' read -r -a parts <<< "$relpath_no_ext"
            encoded_parts=()
            for part in "${parts[@]}"; do
                encoded_parts+=( "$(printf '%s' "$part" | jq -sRr @uri)" )
            done
            encoded_relpath=$(IFS=/; echo "${encoded_parts[*]}")

            if $is_nested; then
              val="  [${name}](${encoded_relpath})"
            else
              val="[${name}](${encoded_relpath})"
            fi
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
        '{{md_fpath}}'

_titlecase string:
    #!/usr/bin/env bash
    set -euo pipefail
    echo "{{titlecase(string)}}"