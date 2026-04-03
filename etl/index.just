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
        # Recursively walk directories, emitting each .md file before the
        # contents of its matching subdirectory. Matching normalizes names
        # (lowercased, spaces/hyphens collapsed) so "2nd Level Foo.md"
        # pairs with directory "2nd-Level Foo/". Version sort (-V) within
        # each directory gives natural numeric ordering (1st before 10th).
        _walk_dir() {
          local wd="$1"
          local -a md_files=() subdirs=()

          for entry in "$wd"/*; do
            [[ -e "$entry" ]] || continue
            if [[ -d "$entry" ]]; then
              subdirs+=("$entry")
            elif [[ "$entry" == *.md ]]; then
              md_files+=("$entry")
            fi
          done

          # Version-sort files and dirs independently
          local -a s_md=() s_dirs=()
          if (( ${#md_files[@]} > 0 )); then
            while IFS= read -r -d '' f; do s_md+=("$f"); done \
              < <(printf '%s\0' "${md_files[@]}" | sort -zV)
          fi
          if (( ${#subdirs[@]} > 0 )); then
            while IFS= read -r -d '' d; do s_dirs+=("$d"); done \
              < <(printf '%s\0' "${subdirs[@]}" | sort -zV)
          fi

          # Build normalized-basename -> dir-path lookup
          local -A dir_by_norm=()
          local d norm
          for d in "${s_dirs[@]}"; do
            norm=$(basename "$d" | tr '[:upper:]' '[:lower:]' | tr ' -' '__')
            dir_by_norm["$norm"]="$d"
          done

          local -A used_dirs=()
          local f stem norm_f
          for f in "${s_md[@]}"; do
            printf '%s\0' "$f"
            stem=$(basename "$f" .md)
            norm_f=$(echo "$stem" | tr '[:upper:]' '[:lower:]' | tr ' -' '__')
            if [[ -n "${dir_by_norm[$norm_f]+x}" ]]; then
              _walk_dir "${dir_by_norm[$norm_f]}"
              used_dirs["${dir_by_norm[$norm_f]}"]=1
            fi
          done

          # Emit contents of any unmatched subdirectories
          for d in "${s_dirs[@]}"; do
            if [[ -z "${used_dirs[$d]+x}" ]]; then
              _walk_dir "$d"
            fi
          done
        }

        sorted_files=()
        while IFS= read -r -d '' f; do
          sorted_files+=("$f")
        done < <(_walk_dir "$dir")
      else
        sorted_files=()
        while IFS= read -r -d '' f; do
          sorted_files+=("$f")
        done < <(printf '%s\0' "$dir"/**/*.md | sort -z -V)
      fi

      # Find the minimum depth among all non-index .md files so we can
      # treat that as the "top level" for nesting purposes.
      min_depth=999
      if [[ -n "{{indent_nested}}" ]]; then
        for f in "${sorted_files[@]}"; do
          [[ -e "$f" ]] || continue
          [[ "$(just index _get_frontmatter_value "type" "$f")" != "index" ]] || continue
          _base=${dir%/}
          _rel=${f#"$_base"/}
          _d=$(echo "$_rel" | tr -cd '/' | wc -c)
          (( _d < min_depth )) && min_depth=$_d
        done
      fi

      for f in "${sorted_files[@]}"; do
        # make sure it actually matched something
        [[ -e $f ]] || continue
        # skip index files
        [[ "$(just index _get_frontmatter_value "type" "$f")" != "index" ]] || continue

        # Determine if this file is nested (deeper than the shallowest files)
        base=${dir%/}
        relpath=${f#"$base"/}
        depth=$(echo "$relpath" | tr -cd '/' | wc -c)
        is_nested=false
        if [[ -n "{{indent_nested}}" ]] && (( depth > min_depth )); then
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
              val=" └── [${name}](${encoded_relpath})"
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