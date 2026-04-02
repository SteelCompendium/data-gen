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

# Generates per-class index files from scc_to_path.json.
# Output structure:
#   output_dpath/{Class}.md          -- lists levels with links to level files
#   output_dpath/{Class}/{Level}.md  -- lists traits, subtraits, and abilities at that level
# source_filter: SCC source prefix to include (e.g. "mcdm.heroes.v1")
gen_class_indexes scc_to_path_json_fpath output_dpath source_filter="mcdm.heroes.v1":
    #!/usr/bin/env python3
    import json
    import re
    from collections import defaultdict
    from pathlib import Path
    from urllib.parse import quote

    scc_map = json.loads(Path("{{scc_to_path_json_fpath}}").read_text())
    output_dir = Path("{{output_dpath}}")
    source_filter = "{{source_filter}}"
    output_dir.mkdir(parents=True, exist_ok=True)

    # Parse SCC keys into a nested structure:
    # classes[class_name][level_key][kind] = [(display_name, path)]
    FEATURE_RE = re.compile(
        r"^(?P<src>[^:]+):feature\.(?P<kind>trait|subtrait|ability)\.(?P<cls>[^.]+)\.(?P<level>[^:]+):(?P<item>.+)$"
    )
    classes = defaultdict(lambda: defaultdict(lambda: defaultdict(list)))

    for scc_key, path in scc_map.items():
        if not scc_key.startswith(source_filter + ":"):
            continue
        m = FEATURE_RE.match(scc_key)
        if not m:
            continue
        cls = m.group("cls")
        level = m.group("level")
        kind = m.group("kind")
        display_name = path.rsplit("/", 1)[-1]
        classes[cls][level][kind].append((display_name, path))

    def level_sort_key(level_str):
        m = re.match(r"(\d+)", level_str)
        return int(m.group(1)) if m else 999

    def level_display(level_str):
        """'1st-level-feature' -> '1st-Level Features'"""
        m = re.match(r"(\d+\w*)-(.+)", level_str)
        if m:
            ordinal = m.group(1)
            rest = m.group(2).replace("-", " ").title()
            return f"{ordinal}-{rest}s"
        return level_str.replace("-", " ").title()

    def encode_path(path):
        return "/".join(quote(seg, safe="") for seg in path.split("/"))

    for cls_name in sorted(classes):
        cls_title = cls_name.replace("-", " ").title()
        levels = classes[cls_name]
        cls_dir = output_dir / cls_title
        cls_dir.mkdir(parents=True, exist_ok=True)

        # -- Class-level file: just lists levels --
        cls_lines = []
        cls_lines.append("---")
        cls_lines.append("type: index")
        cls_lines.append(f"title: '{cls_title} Class Index'")
        cls_lines.append("---")
        cls_lines.append("")
        cls_lines.append(f"# {cls_title}")
        cls_lines.append("")
        cls_lines.append("| Level |")
        cls_lines.append("| --- |")

        for level_key in sorted(levels, key=level_sort_key):
            level_title = level_display(level_key)
            encoded = quote(level_title, safe="")
            cls_lines.append(f"| [{level_title}]({cls_title}/{encoded}) |")

        cls_lines.append("")
        cls_file = output_dir / f"{cls_title}.md"
        cls_file.write_text("\n".join(cls_lines), encoding="utf-8")
        print(f"  Generated: {cls_file}", flush=True)

        # -- Per-level files: list traits, subtraits, abilities --
        for level_key in sorted(levels, key=level_sort_key):
            level_title = level_display(level_key)
            level_data = levels[level_key]

            lvl_lines = []
            lvl_lines.append("---")
            lvl_lines.append("type: index")
            lvl_lines.append(f"title: '{cls_title} {level_title}'")
            lvl_lines.append("---")
            lvl_lines.append("")
            lvl_lines.append(f"# {cls_title}: {level_title}")
            lvl_lines.append("")

            for kind, kind_title in [("trait", "Traits"), ("subtrait", "Subtraits"), ("ability", "Abilities")]:
                items = level_data.get(kind)
                if not items:
                    continue
                items_sorted = sorted(items, key=lambda x: x[0].lower())

                lvl_lines.append(f"## {kind_title}")
                lvl_lines.append("")
                lvl_lines.append("| Name |")
                lvl_lines.append("| --- |")
                for display_name, path in items_sorted:
                    lvl_lines.append(f"| [{display_name}]({encode_path(path)}) |")
                lvl_lines.append("")

            lvl_file = cls_dir / f"{level_title}.md"
            lvl_file.write_text("\n".join(lvl_lines), encoding="utf-8")
            print(f"  Generated: {lvl_file}", flush=True)

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