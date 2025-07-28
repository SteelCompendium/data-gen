# Draw Steel Compendium

_Draw Steel Compendium is an independent product published under the DRAW STEEL Creator [[LICENSE|License]] and is not affiliated with MCDM Productions, LLC. DRAW STEEL © 2025 MCDM Productions, LLC._

This repo does all the heavy lifting of converting packet docs (in markdown form) into alternate formats.  See the `etl`
directory for the conversion logic.  It's a mess, good luck!

Please use this [form to report bugs](https://docs.google.com/forms/d/e/1FAIpQLSc6m-pZ0NLt2EArE-Tcxr-XbAPMyhu40ANHJKtyRvvwBd2LSw/viewform?usp=sharing&ouid=105036387964900154878) if you find them!

## Development 

### Quick Start

- Setup inputs: expected files
  - `input/heroes/Draw Steel Heroes.md`
  - Bunch of "section config" yaml files in `input/heroes/`
- run `devbox run gen` to generate everything
- `git push` all the `data-*` repos that have been updated
- (in the `compendium` project run `just update` to update the website with new `data-*` repo commit)

### Data Flow

```mermaid
flowchart TB
    pdf["PDF: Heroes Book"] --> markdown["Markdown: Heroes Book"]
    
    markdown --> html["HTML: Heroes Book"]
    
    html --> html_chapters["HTML: Chapters"]
    html --> html_abilities["HTML: Abilities"]
    html --> html_dots["HTML: ..."]
    html --> html_kits["HTML: Kits"]
    
    html_chapters --> md_chapters["Markdown: Chapters"]
    html_abilities --> md_abilities["Markdown: Abilities"]
    html_dots --> md_dots["Markdown: ..."]
    html_kits --> md_kits["Markdown: Kits"]
    
    md_chapters --> md_chapters_formatted["Processed Markdown: Chapters"]
    md_abilities --> md_abilities_formatted["Processed Markdown: Abilities"]
    md_dots --> md_dots_formatted["Processed Markdown: ..."]
    md_kits --> md_kits_formatted["Processed Markdown: Kits"]
    
    md_chapters_formatted --> rules_md["Repo: data-rules-md"]
    md_abilities_formatted --> rules_md["Repo: data-rules-md"]
    md_dots_formatted --> rules_md["Repo: data-rules-md"]
    md_kits_formatted --> rules_md["Repo: data-rules-md"]
    
    rules_md --> data_md["Repo: data-md"]
    bestiary_md --> data_md["Repo: data-md"]
    adventures_md --> data_md["Repo: data-md"]

    data_md --> sc_site["SteelCompendium.io site"]
```

