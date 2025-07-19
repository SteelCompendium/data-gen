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
# Usage: `just -f pre_automation_tools/toc.just extract_from "../../Rules/Draw Steel Heroes.md" "../../Rules/toc.md"`
extract_toc markdown_fpath output_fpath:
    #!/usr/bin/env bash
    set -euo pipefail
    grep -E '^#{1,8} ' "{{markdown_fpath}}" > "{{output_fpath}}"