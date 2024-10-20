# Source: https://stackoverflow.com/a/42943426
# I dont understand why this works, but it works
title_case() {
    set ${*,,}
    echo ${*^}
}
