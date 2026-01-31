# Justfile module expected to be named "linker"

##################################################
# Constants and env vars
##################################################

##################################################
# Public Recipes
##################################################

export BASH_ENV := ".utils/.utilsrc"
set shell := ["bash", "-c"]



replace_links md_dpath:
    #!/usr/bin/env bash
    set -euo pipefail

##################################################
# Private Recipes
##################################################

