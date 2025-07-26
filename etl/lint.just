log_prefix := "[JUST][lint]"

markdown md_src_dpath:
    #!/usr/bin/env bash
    set -euo pipefail
    just _print_section "Linting markdown"
    echo >&2 "    MD source: '{{md_src_dpath}}'"
    mdformat --version

    find "{{md_src_dpath}}" -type f -name '*.md' | while read -r fpath; do
        iconv -f UTF-8 -t UTF-8//TRANSLIT "$fpath" -o "$fpath".temp && mv "$fpath".temp "$fpath"
        just frontmatter sort "$fpath"
    done
    mdformat "{{md_src_dpath}}"
