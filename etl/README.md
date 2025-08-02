# ETL Readme

This is a mess, ill clean it up one day...[

## Things to do before pdf

### Heroes

- [ ] More ability metadata
  - type (main action, triggered, etc)
  - for this it might make sense to parse with the sdk and apply metadata from json data

- [ ] classification
  - Bug: The ids (count) increment on every run
    - Need a way to preserve the count between runs
    - reset the count on every run?]()
      - theoretically okay?  Might need an override file...? would get complicated if hundreds of creatures need an off-by-one adjustment

### Monsters

- [ ] Prep monster book stuff
  - [ ] Finalize markdown format for statblocks
  - [ ] Verify markdown parser for statblocks in data-sdk-npm
  - [ ] Section extraction for monster book
  - [ ] data-sdk-npm StatblockMarkdownReader needs to support frontmatter
  - [ ] data-sdk-npm StatblockMarkdownReader needs to get wired into the cli
  - [ ] malice needs to be handled at all levels

### Other

- [ ] Draw Steel Elements plugin support
  - [ ] data-md-dse code to convert abilities/statblocks to dse-codeblocks
- [ ] Ability cards

## TODO

- Glossary links removed
- span anchors were removed - want them back?
- pg 72 diagrams removed
- Bunch of extra data in data formats
  - ex: files for tables
- data file names need to be cleaned of special characters (like `!`)
- go through the toc and figure out what other dedicated pages i want
  - wealth
  - renown
  - gods
- extract out tables
  - kits table
- common abilities are in wrong dir
- docs for classification on the site
- main, massive page stops right-nav at glossary??
  - likely because it cant handle multiple H1 elements in a single doc
- Index pages need more frontmatter
- perks by type
- extra sections in movement (when a creature moves, etc )
- chapters should have a number prefix to sort correctly

Moving on

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

## Development

### Metadata

The generation of metadata is kinda all over the place.  Here are the high-level requirements

- html section extraction (`extract_html_section.just`) requires `xpath` and `file_dpath`
- expansion of section config `section_config.just` requires `header_path`

There are several layers where metadata is generated:

- `ability_config.just`
  - requires
    - toc markdown file
  - generates
    - `header_path`
    - `item_name`
    - `item_id`
    - `type`
    - `feature_type`

- `section_config.just`
  - requires
    - `header_path`
  - generates
    - `xpath`

- `extract_html_section.just`
  - requires
    - `xpath`
    - `file_dpath`
  - generates
    - `item_name`
    - `item_id`

- `sc_classification.just`
  - requires
    - `source`
    - `type`
    - `item_id`
  - generates
    - `scc`
    - `scdc`

- heroes_frontmatter
  - requires/generates type-specific frontmatter

## Future

- [ ] Cards - would be nice to have some kind of downloadable card that people can pull into their tools.  
  - [ ] Image
  - [ ] html
- [ ] auto-linking


## Steel Compendium Decimal Classification

In general, the classification system follows the following schema: `source:type:item`

**Components:**

- **Source** is the document where the facet is found.
- **Type** is the categorization of the facet.
- **Item** is the instance of the facet.

Each of these "components" are separated by the `:` symbol. A component can expand indefinitely to represent as much 
detail as needed and each "code" within a component is separated by a '.' symbol.  

The classification system exists in both a string and decimal form. In string form, each component must be in slug form.
Allowed characters are `[a-zA-Z0-9-]` (subject to change, but keeping it simple for now).  In decimal form, 1-based 
indexing is used and `0` represents the 10th position.  Padding a code is allowed as needed and there can be any number
of digits in a code. 

The only fixed component code is the first which represents the source publisher/producer:

- `1` represents first-party MCDM
- `2` represents any third-party producer
- `3` - `0` are not yet allocated (and may never be)

The remaining codes are generated as needed.  A registration system will eventually be made to ensure global uniqueness.

One facet may be represented by multiple codes. For example, an ability can be categorized in multiple ways:

- Categorized in a full list of all abilities: `mcdm.heroes.v1:abilities:gouge` (`1.1.1:2:138`)
  - "Gouge" is the 138th ability
- Categorized in a list of fury abilities: `mcdm.heroes.v1:abilities.fury:gouge` (`1.1.1:2.4:28`)
  - "Gouge" is also the 28th Fury ability
- Categorized in a list of 2nd-level fury abilities: `mcdm.heroes.v1:abilities.fury.by-level.2nd:gouge` (`1.1.1:2.4.1.2:3`)
  - "Gouge" is also the 3rd ability granted to the Fury at 2nd-level

### Full example

For these examples, we will assume that these items have already been through the registration process.  Note: these 
classification codes are subject to change.

In the first example, lets look at the entire first chapter of the first public release of the MCDM Heroes book.  

| string-code  | decimal-code | Description                                                                                           |
|--------------|--------------|-------------------------------------------------------------------------------------------------------|
| `mcdm`       | `1`          | MCDM is the publisher of this book                                                                    |
| `heroes`     | `1.1`        | The "Heroes" book is the first MCDM publication for Draw Steel                                        |
| `v1`         | `1.1.1`      | "v1" is the first release of the Heroes book pdf (contrived example, actual versioning not yet known) |

This builds our source component: `1.1.1` in decimal form or `mcdm.heroes.v1` in string form.  Likewise, the first 
version of the Monster book would be represented as `1.2.1` in decimal form or `mcdm.monsters.v1` in string form.  

To represent categorization of the first chapter (of the v1 heroes book), we need only a single code for categorization:

| string-code | decimal-code | Description                                   |
|-------------|--------------|-----------------------------------------------|
| `chapters`  | `1`          | Registrar produced this categorization number |

and we only need a single code for the item:

| string-code    | decimal-code | Description                         |
|----------------|--------------|-------------------------------------|
| `introduction` | `1`          | "Introduction" is the first chapter |

In this example, the chapter categorization is the first thing we registered and "Introduction" is the first chapter,
so our final classification for the first chapter of the first release of the MCDM Heroes book is `1.1.1:1:1` in decimal 
form and `mcdm.heroes.v1:chapters:introduction` in string form. 

### Class Ability Example

As another example, lets say we have an ability in the same Heroes book called "Bash in the Face" which is granted to 
the "Censor" class.  In this case we use the same source (`1.1.1`), but the type is categorized as `abilities` with 
sub-code `censor`. Finally, lets say this is the 12th ability that the Censor gets.  The classification would be 
`1.1.1:2.1:12` in decimal form or `mcdm.heroes.v1:abilities.censor:bash-in-the-face` in string form.
