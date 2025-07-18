# ETL Readme

This is a mess, ill clean it up one day...

## Things to do before pdf

- The input heroes markdown needs converted headers - the h7 and h8 need to be brought down
  - Need a plan for this...
  - I need to support anchors to the H8, maybe they are supported by mkdocs.  If so, just need to style them with css
    - Mkdocs will treat an H7 adn H8 as an H6 that starts with "#" or "##" - gross
    - I tried adding <a> tags to the markdown. It doesnt get added to mkdocs ToC and its ugly (hidden) in obsidian
    - I think the plan is to leave it bold in data-rules-md (etc)
    - when it gets pulled over into compendium, replace the...
      - There is no way to differentiate a regular bold from a h8
    - I could add html comments to the line...
    - In markdown (data-rules-md) I think its okay to just leave the H8 as bold and be done. 
    - there is a separate dse repo to handle obsidian if I want to 
    - the data-gen repo could push a modified version of data-md into compendium...
- get rid of the patron4, backer, and patron branches of the site
- Finish the ability prep
  - See below for frontmatter, indexing, wiring into repos
- Wire in ability reader stuff from data-sdk-npm?
- Prep monster book stuff
  - Finalize markdown format for statblocks
  - Verify markdown parser for statblocks in data-sdk-npm
  - Section extraction for monster book
- data-md-dse code
- Style the compendium site in likeness of the pdf (font and color)
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
- [ ] Cards - would be nice to have some kind of downloadable card that people can pull into their tools.  
  - [ ] Image
  - [ ] html
