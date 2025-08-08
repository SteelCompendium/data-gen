log_prefix := "[JUST][md]"

to_html md_src_fpath html_dest_fpath:
    #!/usr/bin/env bash
    set -euo pipefail
    echo >&2 "{{log_prefix}} --- Converting markdown to html --- "
    echo >&2 "{{log_prefix}} MD source: '{{md_src_fpath}}'"
    echo >&2 "{{log_prefix}} HTML dest: '{{html_dest_fpath}}'"

    mkdir -p "$(dirname "{{html_dest_fpath}}")"

    # convert from markdown to html (-f markdown-smart to avoid making ellispses into ... and other smart things)
    pandoc --wrap=none \
        --standalone \
        --section-divs \
        -f markdown-smart \
        -o "{{html_dest_fpath}}" \
        "{{md_src_fpath}}"

    # avoiding some cdata mess
    sed -i 's/<style>/<style type="text\/css">/g' "{{html_dest_fpath}}"

    # tidy up the html
    tidy -i "{{html_dest_fpath}}" > .tmp || true
    mv .tmp "{{html_dest_fpath}}"

    # Replace html entities
    sed -i 's/&#8220;/"/g; s/&#8221;/"/g; s/&amp;/&/g; s/&lt;/</g; s/&gt;/>/g; s/\&nbsp\;/ /g;' "{{html_dest_fpath}}"
    sed -i "s/&#8217;/'/g; s/’/'/g;" "{{html_dest_fpath}}"

# Formats all markdown files in the dir path
lint md_src_dpath:
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

separate_blockquotes md_dpath:
    #!/usr/bin/env bash
    set -euo pipefail
    just _print_section "Separating markdown blockquotes"
    find "{{md_dpath}}" -type f -name '*.md' | while read -r fpath; do
        # inject an html comment between blockquotes
        # https://stackoverflow.com/questions/12979577/how-can-i-write-two-separate-blockquotes-in-sequence-using-markdown
        sed -i -E ':a;N;$!ba;s/\n\n(>)/\n\n<!-- -->\n\1/g' "$fpath"
    done

# Write out the table-of-contents (headers) of a markdown file
#
# Example output:
# # Introduction
# ### What is this Game?
# #### This is an H3 Header
# ##### This is an H4 Header
# ###### This is an H5 Header
# ####### This is an H6 Header
# ######## This is an H7 Header
# ######### This is an H8 Header (8 Cost)
#
# Usage: `just -f pre_automation_tools/toc.just extract_from "../../input/heroes/Draw Steel Heroes.md" "../../input/heroes/toc.md"`
extract_toc markdown_fpath output_fpath:
    #!/usr/bin/env bash
    set -euo pipefail
    grep -E '^#{1,9} ' "{{markdown_fpath}}" > "{{output_fpath}}"