log_prefix := "[JUST][preformat]"

charset md_src_fpath:
    #!/usr/bin/env bash
    set -euo pipefail
    echo >&2 "{{log_prefix}} --- Pre-Formatting Markdown --- "
    echo >&2 "{{log_prefix}} MD source: '{{md_src_fpath}}'"

    # remove BOM
    LANG='en_US.UTF-8' sed -i '1s/^\xef\xbb\xbf//' "{{md_src_fpath}}"
    LANG='en_US.UTF-8' sed -i 's/\xff//g' "{{md_src_fpath}}"
    LANG='en_US.UTF-8' sed -i 's/\xfe//g' "{{md_src_fpath}}"

    # convert everything to UTF-8
    iconv -f UTF-8 -t US-ASCII//TRANSLIT "{{md_src_fpath}}" -o "iconv.temp" && mv "iconv.temp" "{{md_src_fpath}}"

# Remove any bold formatting from headers
remove_bold_in_headers md_src_fpath:
    #!/usr/bin/env bash
    set -euo pipefail
    sed -i -E 's/^(#+)( +)\*\*(.*)\*\*/\1\2\3/' "{{md_src_fpath}}"
