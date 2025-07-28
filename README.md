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
    markdown --> html_dots["..."]
    markdown --> html_perks["HTML: Perks"]
    
    html_chapters --> md_chapters["Markdown: Chapters"]
    html_abilities --> md_abilities["Markdown: Abilities"]
    html_classes --> md_classes["Markdown: Classes"]
    html_treasures --> md_dots["Markdown: ..."]
    html_kits --> md_kits["Markdown: Kits"]
    html_perks --> md_perks["Markdown: Perks"]
    
    md_chapters --> md_chapters_formatted["Processed Markdown: Chapters"]
    md_abilities --> md_abilities_formatted["Processed Markdown: Abilities"]
    md_classes --> md_classes_formatted["Processed Markdown: Classes"]
    md_treasures --> md_dots_formatted["Processed Markdown: ..."]
    md_kits --> md_dots_formatted["Processed Markdown: Kits"]
    md_perks --> md_kits_formatted["Processed Markdown: Perks"]
    
    md_chapters_formatted --> rules_md["Repo: data-rules-md"]
    md_abilities_formatted --> rules_md["Repo: data-rules-md"]
    md_classes_formatted --> rules_md["Repo: data-rules-md"]
    md_dots_formatted --> rules_md["Repo: data-rules-md"]
    md_dots_formatted --> rules_md["Repo: data-rules-md"]
    md_kits_formatted --> rules_md["Repo: data-rules-md"]
    
    rules_md --> data_md["Repo: data-md"]
    bestiary_md --> data_md["Repo: data-md"]
    adventures_md --> data_md["Repo: data-md"]

    data_md --> sc_site["SteelCompendium.io site"]
```

Please use this [form to report bugs](https://docs.google.com/forms/d/e/1FAIpQLSc6m-pZ0NLt2EArE-Tcxr-XbAPMyhu40ANHJKtyRvvwBd2LSw/viewform?usp=sharing&ouid=105036387964900154878) if you find them!