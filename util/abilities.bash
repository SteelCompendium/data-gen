#!/usr/bin/env bash
set -euo pipefail

generate_abilities_for_class() {
    local class="${1:-}"

    abilities_types="$(jq -rc ".${class}[\"1ST-LEVEL FEATURES\"][\"${class} ABILITIES\"] | to_entries | .[]" '../Draw Steel Rules.json')"
    echo "$abilities_types" | while read -r ability_type; do
        local type_raw
        type_raw="$(jq -r '.key' <(echo "$ability_type"))"
        local abilities_raw
        abilities_raw="$(jq -r '.value' <(echo "$ability_type"))"

        local type
        type="$(title_case "$type_raw")"
        if [ "$type" != "Heroic Abilities" ] && [ "$type" != "Kit Signature Ability" ]; then
            abilities_json="$(echo "$abilities_raw" | jq -rc '. | to_entries | .[]')"
            echo "$abilities_json" | while read -r ability; do
                name="$(jq -r '.key' <(echo "$ability"))"
                value="$(jq -r '.value' <(echo "$ability"))"

                local filename
                filename="$(title_case "$name" | sed 's/(.*)//g' | xargs)"
                local folder
                folder="$(title_case "$class")"
                mkdir -p "../Abilities/${folder}"
                ability_to_markdown "$name" "$value" "$class" "$type" > "../Abilities/${folder}/${filename}.md"
            done
        fi
    done
}

ability_to_markdown() {
    local name_raw="${1:-}"
    local value_raw="${2:-}"
    local source_raw="${3:-}"
    local type_raw="${4:-}"

    # Cleanup input
    local name
    name="$(title_case "$name_raw")"
    local source
    source="$(title_case "$source_raw")"

    # Parse cost
    local cost
    cost="$(echo "$name_raw" | sed 's/.*(\(.*\)).*/\1/g')"
    if [ "$cost" == "$name_raw" ]; then
        cost=""
    fi

    # Format ability content
    local content_path
    content_path="$(mktemp)"
    echo "$value_raw" | while read -r val_line; do
        # Handle embedded json arrays (ability keywords, etc)
        if [[ "$val_line" =~ ^\[.*\]$ ]]; then
            echo "$val_line" | sed "s/'/\"/g" | jq -c '.[]' | while read item; do
                echo "\n- ${item}" >> "$content_path"
            done
        elif [[ "$val_line" =~ ^\-\s*\[.*\]$ ]]; then
            echo "$val_line" | sed "s/^-\s*//g" | sed "s/'/\"/g" | jq -c '.[]' | while read item; do
                echo "\n- ${item}" >> "$content_path"
            done
        else
            echo "${val_line}" >> "$content_path"
        fi
    done

    # Build markdown
    markdown="---"
    markdown="${markdown}\nname: \"$name\""
    markdown="${markdown}\ntype: \"$type_raw\""
    markdown="${markdown}\nsource: \"$source\""
    markdown="${markdown}\ncost: \"$cost\""
    markdown="${markdown}\n---"
    markdown="${markdown}\n"
    markdown="${markdown}\n# $name"
    markdown="${markdown}\n"
    markdown="${markdown}\n$(cat "$content_path")"

    # TODO - format the markdown with a linter
    echo -e "$markdown"
}

# Source: https://stackoverflow.com/a/76503202
title_case() {
   ((CHR_PTR=0))
   set ${*,,}
   for f in ${*} ; do
      case $f in
         ebay) c+="eBay " ;;
         mcdonalds|"mcdonald's") c+="McDonald's " ;;
         vs) c+="vs. " ;;
         a|about|and|but|by|for|in|is|of|or|the|to) \
             [ "$CHR_PTR" -eq "0" ] && {
                c+="${f^} "
             } || {
                c+="$f "
             } ;;
         bbq|diy|hdtv|hf|kfc|mdf|sdtv|shf|tv|uhf|vlf|vhf) c+="${f^^} " ;;
         *) c+="${f^} " ;;
      esac
      ((CHR_PTR++))
   done
   x=${c## } ; c=${x%% }
   echo "$c"
}