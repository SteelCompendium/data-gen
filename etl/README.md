# ETL Readme

This is a mess, ill clean it up one day...

## Things to do before pdf

- Finish the ability prep
  - See below for frontmatter, indexing, wiring into repos
- Wire in ability reader stuff from data-sdk-npm?
- Prep monster book stuff
  - Finalize markdown format for statblocks
  - Verify markdown parser for statblocks in data-sdk-npm
  - Section extraction for monster book
- data-md-dse code to convert abilities/statblocks to dse-codeblocks
- Change discord nickname to `Xentis (Steel Compendium)`

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
   - [ ] Generate the `abilities.yml` file using `abilities.just`
   - [ ] Extract ability sections (`abilities.just`)
   - [ ] Frontmatter (TODO - code)
   - [ ] Lint the abilities (TODO - code)
   - [ ] Build ability indexes (TODO - code)
   - [ ] Wire into the repos (TODO - code)
- [ ] Move to monster book (TODO - code)
- [ ] draw-steel-elements
  - [ ] Prepare the `data-md-dse` repo (TODO - code)
  - [ ] Prepare the `data-bestiary-md-dse` repo (TODO - code)
  - [ ] Update DSE to `main` branch
- [ ] Move to adventures (TODO - code)

## Future

- [ ] Cards - would be nice to have some kind of downloadable card that people can pull into their tools.  
  - [ ] Image
  - [ ] html
