# Draw Steel Compendium

_Draw Steel Compendium is an independent product published under the DRAW STEEL Creator [[LICENSE|License]] and is not affiliated with MCDM Productions, LLC. DRAW STEEL © 2025 MCDM Productions, LLC._

This repo does all the heavy lifting of converting packet docs (in markdown form) into alternate formats.  See the `etl`
directory for the conversion logic.  It's a mess, good luck!

## Data Flow

```mermaid
flowchart TB
    pdf["PDF"] --> markdown["Markdown"]
    
    markdown --> html_chapters["HTML: Chapters"]
    markdown --> html_abilities["HTML: Abilities"]
    markdown --> html_classes["HTML: Classes"]
    markdown --> html_treasures["HTML: Treasures"]
    markdown --> html_kits["HTML: Kits"]
    markdown --> html_perks["HTML: Perks"]
    
    html_chapters --> md_chapters["Markdown: Chapters"]
    html_abilities --> md_abilities["Markdown: Abilities"]
    html_classes --> md_classes["Markdown: Classes"]
    html_treasures --> md_treasures["Markdown: Treasures"]
    html_kits --> md_kits["Markdown: Kits"]
    html_perks --> md_perks["Markdown: Perks"]
    
    md_chapters --> formatter["Markdown Formatter"]
    md_abilities --> formatter["Markdown Formatter"]
    md_classes --> formatter["Markdown Formatter"]
    md_treasures --> formatter["Markdown Formatter"]
    md_kits --> formatter["Markdown Formatter"]
    md_perks --> formatter["Markdown Formatter"]
    
    formatter --> auto_linker["Auto-linker"]
    
    auto_linker --> rules_md["Repo: data-rules-md"]
    auto_linker --> bestiary_md["Repo: data-bestiary-md"]
    auto_linker --> adventures_md["Repo: data-adventures-md"]
    
    rules_md --> data_md["Repo: data-md"]
    bestiary_md --> data_md["Repo: data-md"]
    adventures_md --> data_md["Repo: data-md"]
```