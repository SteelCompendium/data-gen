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
    import yaml, subprocess
    from pathlib import Path
    import frontmatter

    def generate_for_abilities(rel_path: Path, metadata: dict, body: str) -> dict:
        # Run the external command and capture the YAML output
        result = subprocess.run(
            ["just", "abilities", "convert", str(rel_path), "yaml"],
            check=True,
            stdout=subprocess.PIPE,
            text=True
        )
        yaml_data = yaml.safe_load(result.stdout)
        for key in ("flavor", "keywords", "type", "distance", "target"):
            if key in yaml_data:
                if key == "type":
                    metadata["action_type"] = yaml_data[key]
                else:
                    metadata[key] = yaml_data[key]

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
        ch_num = int(metadata["chapter_num"])
        ch_name = metadata["item_name"]
        return {
            "title": f'Chapter {ch_num}: {ch_name}',
        }

    def generate_for_cultures(rel_path: Path, metadata: dict, body: str) -> dict:
            parts = metadata["type"].strip("/").split("/")
            culture_benefit_type = parts[1]
            return {
                "culture_benefit_type": culture_benefit_type.strip().title()
            }

    def generate_for_titles(rel_path: Path, metadata: dict, body: str) -> dict:
        m = re.search(r'(?<=/)\d+(?:st|nd|rd|th)(?=-)', metadata["type"])
        ordinal = m.group(0).strip() if m else None
        return {"echelon": ordinal}

    def generate_for_treasures(rel_path: Path, metadata: dict, body: str) -> dict:
        parts = metadata["type"].strip("/").split("/")
        treasure_type = parts[-2]
        last_segment = parts[-1]

        m = re.match(r'(?i)^\d+(?:st|nd|rd|th)(?=-|$)', last_segment)
        ordinal = m.group(0).strip() if m else None
        return {
            "treasure_type": treasure_type.strip().title(),
            "echelon": ordinal
        }

    def default_generator(rel_path: Path, metadata: dict, body: str) -> dict:
        return {}

    # TODO - make more metadata generators for different types when I have data
    DISPATCH = {
        re.compile(r"Abilities/"): generate_for_abilities,
        re.compile(r"Chapters/"): generate_for_chapters,
        re.compile(r"Cultures/"): generate_for_cultures,
        re.compile(r"Titles/"): generate_for_titles,
        re.compile(r"Treasures/"): generate_for_treasures,
    }

    def get_generator(rel_path: Path):
        rel_path_str = rel_path.as_posix()
        for pattern, generator in DISPATCH.items():
            if pattern.match(rel_path_str):
                return generator
        return default_generator

    def process_file(filepath: Path, root: Path):
        post = frontmatter.load(filepath)
        body = post.content
        rel_path = filepath.relative_to(root)
        generator = get_generator(rel_path)
        new_metadata = generator(filepath, post.metadata, body)
        post.metadata.update(new_metadata)
        filepath.write_text(frontmatter.dumps(post), encoding='utf-8')

    if __name__ == "__main__":
        root_dir = Path("{{md_dpath}}").resolve()
        for md_file in root_dir.rglob("*.md"):
            process_file(md_file, root_dir)
