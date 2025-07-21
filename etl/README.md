# ETL Readme

This is a mess, ill clean it up one day...

## Things to do before pdf

- [ ] Abilities
  - [x] Extract abilities into json/yaml/xml and moved into appropriate data-* repos
  - [x] Wire in ability reader stuff from data-sdk-npm?
  - [x] Fix abilityMarkdownReader to handle frontmatter
  - [x] Make sure sc-convert supports abilities and statblocks (should I add another flag?)

- [ ] Support XML in data-sdk-npm
  - [ ] schema
  - [ ] reader
  - [ ] writer
  - [ ] tests
  - [ ] Add to cli
  - [ ] Add to web-adapter site

- [ ] data-sdk-npm 
  - [ ] is missing tests for json??? maybe yaml ability too?
  - [ ] Support metadata
    - class, subclass, level, creature, etc

- [ ] Enhancements for mundane files
  - [ ] frontmatter generation for all files (more than abilities)
    - kit abilities should have a subtype or something?
  - [ ] indexes for resources (other than abilities)
    - See "compendium/docs/Rules/Draw Steel Heroes - Unlinked.md" for example of custom name (frontmatter title)
    - Basically anything generated from extract_sections should get an index
      - Before this happens, that all needs frontmatter generation
  - [ ] More metadata/frontmatter in abilities
    - [ ] add some kind of UUID (`book.type.hash` or something) 
      - Fantasy Grounds needs an id in form `id-00001` and it doesnt support migrations afaik
        - Because of this, I think we will need id override mapping support (if you find X, ignore and give id Y) 

- [ ] auto-linking 
  - Check index files to verify they link

- [ ] Prep monster book stuff
  - [ ] Finalize markdown format for statblocks
  - [ ] Verify markdown parser for statblocks in data-sdk-npm
  - [ ] Section extraction for monster book
  - [ ] data-sdk-npm StatblockMarkdownReader needs to support frontmatter
  - [ ] data-sdk-npm StatblockMarkdownReader needs to get wired into the cli

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
