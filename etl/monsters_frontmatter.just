# Justfile module expected to be named "monsters_frontmatter"

##################################################
# Constants and env vars
##################################################

##################################################
# Public Recipes
##################################################

# processes the frontmatter for all markdown files in a directory
generate md_dpath:
    #!/usr/bin/env python3
    import sys, re
    import yaml, subprocess
    from pathlib import Path
    import frontmatter

    def statblocks_generator(rel_path: Path, metadata: dict, body: str) -> dict:
        print(rel_path)
        # Run the external command and capture the YAML output
        result = subprocess.run(
            ["just", "statblocks", "convert", str(rel_path), "yaml"],
            check=True,
            stdout=subprocess.PIPE,
            text=True
        )
        yaml_data = yaml.safe_load(result.stdout)
        return {
            "item_id": metadata["item_id"],
            "level": yaml_data['level'],
            "roles": yaml_data['roles'],
            "ancestry": yaml_data["ancestry"],
            "ev": yaml_data['ev'],
            "stamina": yaml_data['stamina'],
            "speed": yaml_data['speed'],
            "size": yaml_data['size'],
            "stability": yaml_data['stability'],
            "free_strike": yaml_data['free_strike'],
            "might": yaml_data['might'],
            "agility": yaml_data['agility'],
            "reason": yaml_data['reason'],
            "intuition": yaml_data['intuition'],
            "presence": yaml_data['presence']
        }

    def default_generator(rel_path: Path, metadata: dict, body: str) -> dict:
        return {}

    DISPATCH = {
        re.compile(r"^.*/Statblocks/"): statblocks_generator,
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
