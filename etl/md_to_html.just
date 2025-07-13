log_prefix := "[JUST][md_to_html]"

run md_src_fpath html_dest_fpath:
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
