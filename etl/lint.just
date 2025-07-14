log_prefix := "[JUST][lint]"

markdown md_src_dpath:
    #!/usr/bin/env bash
    set -euo pipefail
    just _print_section "Linting markdown"
    echo >&2 "    MD source: '{{md_src_dpath}}'"
    mdformat --version

    # convert everything to UTF-8
    find "{{md_src_dpath}}" -type f -name '*.md' -exec sh -c '
      for file do
        # Convert "file" in place, making a backup with a .bak extension
        echo "$file"
        iconv -f UTF-8 -t UTF-8//TRANSLIT "$file" -o "$file".temp && mv "$file".temp "$file"
      done
    ' sh {} +
    mdformat "{{md_src_dpath}}"
