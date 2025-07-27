# Justfile module expected to be named "heroes_frontmatter"

##################################################
# Constants and env vars
##################################################

##################################################
# Public Recipes
##################################################

# processes the frontmatter for all markdown files in a directory
generate md_dpath:
    #!/usr/bin/env python3
    '''
    generate_frontmatter.py

    Scan a directory of Markdown files, for each file:
      - Determine its path relative to the provided root directory
      - Select a frontmatter-generator based on that path
      - Load existing frontmatter and body via python-frontmatter
      - Call generator(rel_path, metadata, body)
      - Update metadata and rewrite file
    '''
    import sys, re
    from pathlib import Path
    import frontmatter

    def generate_for_abilities(rel_path: Path, metadata: dict, body: str) -> dict:
        # cost and sub-values + type
        assumed_base_type = 'feature/trait'
        m = re.match(r'^(.*?)\s*\((.*?)\)\s*$', metadata['item_name'])
        if m:
            metadata["cost"] = m.group(2)
            m = re.match(r'^([0-9+]+)\s+(.+)$', metadata["cost"].strip())
            if m:
                metadata["cost_amount"], metadata["cost_resource"] = int(m.group(1)), m.group(2)
                assumed_base_type = 'feature/ability'

        # level
        match = re.search(r'((\d+)(?:st|nd|rd|th)-level-feature)s', metadata['header_path'])
        if match:
            metadata['level'] = int(match.group(2))
            level_feature = match.group(1)

        # class
        metadata['class'] = metadata['header_path'].split('/')[0]

        return metadata

    def generate_for_chapters(rel_path: Path, metadata: dict, body: str) -> dict:
        return {"chapter_num": int(metadata["item_index"])}

    def generate_for_titles(rel_path: Path, metadata: dict, body: str) -> dict:
        m = re.match(r'([0-9+]+)', metadata["type"])
        if m:
            return {"echelon": m.group(1).strip()}
        return {}

    def generate_for_treasures(rel_path: Path, metadata: dict, body: str) -> dict:
        m = re.match(r'^treasures/([^0-9]*)', metadata["type"])
        if m:
            return {"treasure_type": m.group(1).strip().title()}
        return {}

    def default_generator(rel_path: Path, metadata: dict, body: str) -> dict:
        return {}

    # TODO - make more metadata generators for different types when I have data
    DISPATCH = {
        'Abilities': generate_for_abilities,
        'Chapters': generate_for_chapters,
        'Titles': generate_for_titles,
    }

    def get_generator(rel_path: Path):
        first = rel_path.parts[0] if rel_path.parts else None
        return DISPATCH.get(first, default_generator)

    def process_file(filepath: Path, root: Path):
        post = frontmatter.load(filepath)
        body = post.content
        rel = filepath.relative_to(root)
        gen = get_generator(rel)
        new_meta = gen(rel, post.metadata, body)
        post.metadata.update(new_meta)
        filepath.write_text(frontmatter.dumps(post), encoding='utf-8')

    root_dir = Path("{{md_dpath}}")
    for md_file in root_dir.rglob('*.md'):
        process_file(md_file, root_dir)
