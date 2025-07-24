# Justfile module expected to be named "extract_hero_sections"

##################################################
# Constants and env vars
##################################################

log_prefix := "[JUST][extract_html_sections]"

input_dpath := `just _input_dpath` / 'heroes'
heroes_staging_dpath := `just _staging_dpath` / "heroes"
sections_staging_dpath := heroes_staging_dpath / "0_sections"

##################################################
# Public Recipes
##################################################

run heroes_html_fpath output_dpath:
    echo "Extracting Hero sections from '{{heroes_html_fpath}}'"
    just extract_heroes_sections _extract_chapters "{{heroes_html_fpath}}" "{{output_dpath}}"
    just extract_heroes_sections _extract_classes "{{heroes_html_fpath}}" "{{output_dpath}}"
    just extract_heroes_sections _extract_abilities "{{heroes_html_fpath}}" "{{output_dpath}}"
    just extract_heroes_sections _extract_movement "{{heroes_html_fpath}}" "{{output_dpath}}"
    just extract_heroes_sections _extract_kits "{{heroes_html_fpath}}" "{{output_dpath}}"
    just extract_heroes_sections _extract_ancestries "{{heroes_html_fpath}}" "{{output_dpath}}"
    just extract_heroes_sections _extract_careers "{{heroes_html_fpath}}" "{{output_dpath}}"
    just extract_heroes_sections _extract_cultures "{{heroes_html_fpath}}" "{{output_dpath}}"
    just extract_heroes_sections _extract_complications "{{heroes_html_fpath}}" "{{output_dpath}}"
    just extract_heroes_sections _extract_conditions "{{heroes_html_fpath}}" "{{output_dpath}}"
    just extract_heroes_sections _extract_skills "{{heroes_html_fpath}}" "{{output_dpath}}"
    just extract_heroes_sections _extract_negotiation "{{heroes_html_fpath}}" "{{output_dpath}}"
    just extract_heroes_sections _extract_perks "{{heroes_html_fpath}}" "{{output_dpath}}"
    just extract_heroes_sections _extract_titles "{{heroes_html_fpath}}" "{{output_dpath}}"
    just extract_heroes_sections _extract_treasures "{{heroes_html_fpath}}" "{{output_dpath}}"

##################################################
# Private Recipes
##################################################

# helper to expand a config and then extract it
_expand_and_extract config_fpath html_fpath output_dpath:
    #!/usr/bin/env bash
    set -euo pipefail
    mkdir -p "{{output_dpath}}"
    mkdir -p "{{sections_staging_dpath}}"
    expanded_config_fpath="{{sections_staging_dpath}}/$(basename "{{config_fpath}}")"
    cp "{{config_fpath}}" "$expanded_config_fpath"
    just extract_section_config expand_general "$expanded_config_fpath"
    just extract_html_sections extract_sections "$expanded_config_fpath" "{{html_fpath}}" "{{output_dpath}}" "skip_delete"

_extract_chapters heroes_html_fpath output_dpath:
    #!/usr/bin/env bash
    set -euo pipefail
    just extract_heroes_sections _expand_and_extract "{{input_dpath}}/chapters.yml" "{{heroes_html_fpath}}" "{{output_dpath}}/Chapters"

_extract_classes heroes_html_fpath output_dpath:
    #!/usr/bin/env bash
    set -euo pipefail
    just extract_heroes_sections _expand_and_extract "{{input_dpath}}/classes.yml" "{{heroes_html_fpath}}" "{{output_dpath}}/Classes"

_extract_abilities heroes_html_fpath output_dpath:
    #!/usr/bin/env bash
    set -euo pipefail
    just extract_heroes_sections _expand_and_extract "{{input_dpath}}/common_abilities.yml" "{{heroes_html_fpath}}" "{{output_dpath}}/Abilities"

_extract_movement heroes_html_fpath output_dpath:
    #!/usr/bin/env bash
    set -euo pipefail
    movement_path="{{output_dpath}}/Movement"
    xpath="//section[@id='combat']//section[@id='movement']//section[@class='level5']"
    just extract_html_sections extract_section "$movement_path" "$xpath" "{{heroes_html_fpath}}"
    xpath="//section[@id='combat']//section[@id='movement-types']//section[@class='level6']"
    just extract_html_sections extract_section "$movement_path" "$xpath" "{{heroes_html_fpath}}" "skip_delete"

    #rm "${movement_path}/CanT Exceed Speed.html"
    #rm "${movement_path}/Movement Types.html"

_extract_kits heroes_html_fpath output_dpath:
    #!/usr/bin/env bash
    set -euo pipefail
    martial_path="{{output_dpath}}/Kits"
    xpath="//section[@id='kits']//section[@id='kits-a-to-z']//section[@class='level5']"
    just extract_html_sections extract_section "$martial_path" "$xpath" "{{heroes_html_fpath}}"

_extract_ancestries heroes_html_fpath output_dpath:
    #!/usr/bin/env bash
    set -euo pipefail
    ancestries_path="{{output_dpath}}/Ancestries"
    xpath="//section[@id='ancestries']//section[@class='level2']"
    just extract_html_sections extract_section "$ancestries_path" "$xpath" "{{heroes_html_fpath}}"

    # removes any extra sections
    #rm "${ancestries_path}/Starting Size And Speed.html"
    #rm "${ancestries_path}/On The Origin Of Species.html"

_extract_careers heroes_html_fpath output_dpath:
    #!/usr/bin/env bash
    set -euo pipefail
    careers_path="{{output_dpath}}/Careers"
    xpath="//section[@id='careers-a-to-z']//section[@class='level4']"
    just extract_html_sections extract_section "$careers_path" "$xpath" "{{heroes_html_fpath}}"

    # removes any extra sections
    # rm "${careers_path}/Career Benefits.html"
    # rm "${careers_path}/Career Questions.html"
    # rm "${careers_path}/Inciting Incident.html"

_extract_cultures heroes_html_fpath output_dpath:
    #!/usr/bin/env bash
    set -euo pipefail
    cultures_path="{{output_dpath}}/Cultures"

    xpath="//section[@id='culture-benefits']//section[@id='environment']//section[@class='level6']"
    just extract_html_sections extract_section "$cultures_path/Environments" "$xpath" "{{heroes_html_fpath}}"

    xpath="//section[@id='culture-benefits']//section[@id='organization']//section[@class='level6']"
    just extract_html_sections extract_section "$cultures_path/Organizations" "$xpath" "{{heroes_html_fpath}}"

    xpath="//section[@id='culture-benefits']//section[@id='upbringing']//section[@class='level6']"
    just extract_html_sections extract_section "$cultures_path/Upbringing" "$xpath" "{{heroes_html_fpath}}"

_extract_complications heroes_html_fpath output_dpath:
    #!/usr/bin/env bash
    set -euo pipefail
    complications_path="{{output_dpath}}/Complications"
    xpath="//section[@id='complications']//section[@id='determine-complication']//section[@class='level5']"
    just extract_html_sections extract_section "$complications_path" "$xpath" "{{heroes_html_fpath}}"

_extract_conditions heroes_html_fpath output_dpath:
    #!/usr/bin/env bash
    set -euo pipefail
    conditions_path="{{output_dpath}}/Conditions"
    xpath="//section[@id='conditions']//section[@class='level4']"
    just extract_html_sections extract_section "$conditions_path" "$xpath" "{{heroes_html_fpath}}"

# Note: the original markdown needed to be adjusted to ensure the callouts arent picked up (which error)
_extract_skills heroes_html_fpath output_dpath:
    #!/usr/bin/env bash
    set -euo pipefail
    skills_path="{{output_dpath}}/Skills"
    xpath="//section[@id='skill-groups']//section[@class='level6']"
    just extract_html_sections extract_section "$skills_path" "$xpath" "{{heroes_html_fpath}}"

# Note: the original markdown needed to be adjusted to ensure the callouts arent picked up (which error)
_extract_negotiation heroes_html_fpath output_dpath:
    #!/usr/bin/env bash
    set -euo pipefail
    negotiation_path="{{output_dpath}}/Negotiation"
    xpath="//section[@id='list-of-motivations-and-pitfalls']//section[@class='level6']"
    just extract_html_sections extract_section "$negotiation_path/Motivations and Pitfalls" "$xpath" "{{heroes_html_fpath}}"

_extract_perks heroes_html_fpath output_dpath:
    #!/usr/bin/env bash
    set -euo pipefail
    perks_path="{{output_dpath}}/Perks"
    xpath="//section[@id='crafting-perks']//section[@class='level5']"
    just extract_html_sections extract_section "${perks_path}/Crafting Perks" "$xpath" "{{heroes_html_fpath}}"
    xpath="//section[@id='exploration-perks']//section[@class='level5']"
    just extract_html_sections extract_section "${perks_path}/Exploration Perks" "$xpath" "{{heroes_html_fpath}}"
    xpath="//section[@id='interpersonal-perks']//section[@class='level5']"
    just extract_html_sections extract_section "${perks_path}/Interpersonal Perks" "$xpath" "{{heroes_html_fpath}}"
    xpath="//section[@id='intrigue-perks']//section[@class='level5']"
    just extract_html_sections extract_section "${perks_path}/Intrigue Perks" "$xpath" "{{heroes_html_fpath}}"
    xpath="//section[@id='lore-perks']//section[@class='level5']"
    just extract_html_sections extract_section "${perks_path}/Lore Perks" "$xpath" "{{heroes_html_fpath}}"
    xpath="//section[@id='supernatural-perks']//section[@class='level5']"
    just extract_html_sections extract_section "${perks_path}/Supernatural Perks" "$xpath" "{{heroes_html_fpath}}"

_extract_titles heroes_html_fpath output_dpath:
    #!/usr/bin/env bash
    set -euo pipefail
    titles_path="{{output_dpath}}/Titles"
    xpath="//section[@id='st-echelon-titles']//section[@class='level5']"
    just extract_html_sections extract_section "${titles_path}/1st Echelon" "$xpath" "{{heroes_html_fpath}}"
    xpath="//section[@id='nd-echelon-titles']//section[@class='level5']"
    just extract_html_sections extract_section "${titles_path}/2nd Echelon" "$xpath" "{{heroes_html_fpath}}"
    xpath="//section[@id='rd-echelon-titles']//section[@class='level5']"
    just extract_html_sections extract_section "${titles_path}/3rd Echelon" "$xpath" "{{heroes_html_fpath}}"
    xpath="//section[@id='th-echelon-titles']//section[@class='level5']"
    just extract_html_sections extract_section "${titles_path}/4th Echelon" "$xpath" "{{heroes_html_fpath}}"

_extract_treasures heroes_html_fpath output_dpath:
    #!/usr/bin/env bash
    set -euo pipefail
    treasures_path="{{output_dpath}}/Treasures"
    
    # Consumables
    xpath="//section[@id='st-echelon-consumables']//section[@class='level6']"
    just extract_html_sections extract_section "${treasures_path}/Consumables/1st Echelon Consumables" "$xpath" "{{heroes_html_fpath}}"
    xpath="//section[@id='nd-echelon-consumables']//section[@class='level6']"
    just extract_html_sections extract_section "${treasures_path}/Consumables/2nd Echelon Consumables" "$xpath" "{{heroes_html_fpath}}"
    xpath="//section[@id='rd-echelon-consumables']//section[@class='level6']"
    just extract_html_sections extract_section "${treasures_path}/Consumables/3rd Echelon Consumables" "$xpath" "{{heroes_html_fpath}}"
    xpath="//section[@id='th-echelon-consumables']//section[@class='level6']"
    just extract_html_sections extract_section "${treasures_path}/Consumables/4th Echelon Consumables" "$xpath" "{{heroes_html_fpath}}"

    # Trinkets
    xpath="//section[@id='st-echelon-trinkets']//section[@class='level6']"
    just extract_html_sections extract_section "${treasures_path}/Trinkets/1st Echelon Trinkets" "$xpath" "{{heroes_html_fpath}}"
    xpath="//section[@id='nd-echelon-trinkets']//section[@class='level6']"
    just extract_html_sections extract_section "${treasures_path}/Trinkets/2nd Echelon Trinkets" "$xpath" "{{heroes_html_fpath}}"
    xpath="//section[@id='rd-echelon-trinkets']//section[@class='level6']"
    just extract_html_sections extract_section "${treasures_path}/Trinkets/3rd Echelon Trinkets" "$xpath" "{{heroes_html_fpath}}"
    xpath="//section[@id='th-echelon-trinkets']//section[@class='level6']"
    just extract_html_sections extract_section "${treasures_path}/Trinkets/4th Echelon Trinkets" "$xpath" "{{heroes_html_fpath}}"

    # Leveled Treasures
    xpath="//section[@id='leveled-armor-treasures']//section[@class='level6']"
    just extract_html_sections extract_section "${treasures_path}/Leveled Treasures/Leveled Armor Treasures" "$xpath" "{{heroes_html_fpath}}"
    xpath="//section[@id='leveled-implement-treasures']//section[@class='level6']"
    just extract_html_sections extract_section "${treasures_path}/Leveled Treasures/Leveled Implement Treasures" "$xpath" "{{heroes_html_fpath}}"
    xpath="//section[@id='leveled-weapon-treasures']//section[@class='level6']"
    just extract_html_sections extract_section "${treasures_path}/Leveled Treasures/Leveled Weapon Treasures" "$xpath" "{{heroes_html_fpath}}"
    xpath="//section[@id='other-leveled-treasures']//section[@class='level6']"
    just extract_html_sections extract_section "${treasures_path}/Leveled Treasures/Other Leveled Treasures" "$xpath" "{{heroes_html_fpath}}"
    xpath="//section[@id='artifacts']//section[@class='level6']"
    just extract_html_sections extract_section "${treasures_path}/Artifacts" "$xpath" "{{heroes_html_fpath}}"
    
# TODO - downtime stuff
