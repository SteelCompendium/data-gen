# ETL Readme

This is a mess, ill clean it up one day...

## Things to do before pdf

- [ ] metadata: there is metadata being generated all over the place
  - extract_html_section makes the item_name and item_id (id should be moved out)
  - Some is generated in section_config
  - abilities and ability_config is its own mess
  - frontmatter only deletes right now?

- [ ] Remove `section_name` from section_cofnig.yml files

- [ ] add "feature_type" to frontmatter of abilities

- [ ] classification
  - Bug: The ids (count) increment on every run 
    - Need a way to preserve the count between runs
    - reset the count on every run?
      - theoretically okay?  Might need an override file...? would get complicated if hundreds of creatures need an off-by-one adjustment

- [ ] Enhancements for mundane files
  - [ ] unique frontmatter generation for each section (chapter=chapter_number) 
  - [ ] Add front matter to index tables
 
- [ ] Custom index name for mkdocs?
  - See "compendium/docs/Rules/Draw Steel Heroes - Unlinked.md" for example of custom name (frontmatter title)

- [ ] auto-linking 
  - Check index files to verify they link

- [ ] Prep monster book stuff
  - [ ] Finalize markdown format for statblocks
  - [ ] Verify markdown parser for statblocks in data-sdk-npm
  - [ ] Section extraction for monster book
  - [ ] data-sdk-npm StatblockMarkdownReader needs to support frontmatter
  - [ ] data-sdk-npm StatblockMarkdownReader needs to get wired into the cli
  - [ ] malice needs to be handled at all levels

- [ ] Draw Steel Elements plugin support
  - [ ] data-md-dse code to convert abilities/statblocks to dse-codeblocks

- [ ] Other
  - [ ] Change discord nickname to `Xentis (Steel Compendium)`
  - [ ] Ability cards repo?

## Plan for final PDF

- [ ] Convert with marker, save to `Rules/Draw Steel Heroes_marker_full.md`
- [ ] Split into Chapters, save each to `Rules/Draw Steel Heroes_wip_ch1.md`
- [ ] Work in chunks (each chapter) to get markdown fully cleaned up. When chapter is converted, move it into `Rules/Draw Steel Heroes.md`
  - [ ] Chapter 1
  - [ ] Chapter 2
  - [ ] Chapter 3
  - [ ] Chapter 4
  - [ ] Chapter 5
  - [ ] Chapter 6
  - [ ] Chapter 7
  - [ ] Chapter 8
  - [ ] Chapter 9
  - [ ] Chapter 10
  - [ ] Chapter 11
  - [ ] Chapter 12
  - [ ] Chapter 13
  - [ ] Chapter 14
  - [ ] Chapter 15
- [ ] Publish final chunks as they are completed to the site (TODO - code for site to use main branch)
- [ ] When markdown is fully converted and clean, run ETL E2E for sections, etc
- [ ] Abilities
- [ ] Move to monster book (TODO - code)
- [ ] draw-steel-elements
  - [ ] Prepare the `data-md-dse` repo (TODO - code)
  - [ ] Prepare the `data-bestiary-md-dse` repo (TODO - code)
  - [ ] Update DSE to `main` branch
- [ ] Move to adventures (TODO - code)

### Guidance for chapter markdown cleanup

- pre-cleanup (line removals, see what preformat.just does... maybe nothing)
- do headers first
  - Can go up to H7 (which will convert to bold)
  - H8 is reserved for abilities (not features). Ever ability must be an H8 in order for ability automation to work
- once headers are done, focus on the content
  - power roll formatter
  - line replacement
- manual fixes from there

## Future

- [ ] Cards - would be nice to have some kind of downloadable card that people can pull into their tools.  
  - [ ] Image
  - [ ] html

### Steel Compendium Decimal Classification

source:section:item

~~source type (rules, bestiary)~~
(1) source publisher? (MCDM, 3rd party, homebrew?)
(4) source (Heroes, Monsters)
(2) source version (1)
:
delimeter (chapter, abilities, monster type)
:
item_index

## example

- chapter
  - `1.1.1:1:001`
  - `MCDM.Heroes.v1:chapters:introduction`
- ability
  - `1.1.1:2.1:001`
  - `MCDM.Heroes.v1:abilities.censor:bash-in-the-face`