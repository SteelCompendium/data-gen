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
extract_from markdown_fpath output_fpath:
    #!/usr/bin/env bash
    set -euo pipefail
    grep -E '^#{1,8} ' "{{markdown_fpath}}" > "{{output_fpath}}"