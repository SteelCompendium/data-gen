# Justfile module expected to be named "linker"

##################################################
# Constants and env vars
##################################################

##################################################
# Public Recipes
##################################################

remove_scc_links md_dpath:
    #!/usr/bin/env python3
    import re
    from pathlib import Path

    MD_DPATH = Path("{{md_dpath}}")

    def process_file(md_path: Path):
        content = md_path.read_text(encoding="utf-8")
        new_content = re.sub(r'\[([^\]]+)\]\(scc:[^\)]+\)', r'\1', content)

        if new_content != content:
            md_path.write_text(new_content, encoding="utf-8")

    def main():
        if not MD_DPATH.exists():
            print(f"Directory {MD_DPATH} does not exist.")
            return

        for md in MD_DPATH.rglob("*.md"):
            process_file(md)

    if __name__ == "__main__":
        main()

apply_scc_links md_dpath scc_to_path_json_fpath:
    #!/usr/bin/env python3
    import json
    import re
    import urllib.parse
    from pathlib import Path

    MD_DPATH = Path("{{md_dpath}}")
    SCC_TO_PATH_JSON_FILE = Path("{{scc_to_path_json_fpath}}")

    URL_PREFIX = "REL_PATH_PREFIX"
    URL_SUFFIX = "REL_PATH_SUFFIX"

    def load_scc_map():
        if SCC_TO_PATH_JSON_FILE.exists():
            return json.loads(SCC_TO_PATH_JSON_FILE.read_text())
        return {}

    def process_file(md_path: Path, scc_map):
        content = md_path.read_text(encoding="utf-8")
        
        # Only replace in the body, so split frontmatter if present
        parts = content.split("---", 2)
        if len(parts) >= 3:
             # parts[0] is empty (before first ---)
             # parts[1] is frontmatter
             # parts[2] is body
             body = parts[2]
             
             new_body = body
             # Find all scc: occurrences
             for match in re.finditer(r'\(scc:([^\)]+)\)', body):
                 full_match = match.group(0)
                 scc_key = match.group(1) # The part after "scc:"
                 if scc_key in scc_map:
                     quoted_path = urllib.parse.quote(scc_map[scc_key])
                     replacement = "(" + URL_PREFIX + quoted_path + URL_SUFFIX +")"
                     new_body = new_body.replace(full_match, replacement)
            
             if new_body != body:
                 # Reconstruct content
                 new_content = f"---{parts[1]}---{new_body}"
                 md_path.write_text(new_content, encoding="utf-8")
        else:
             new_content = content
             for match in re.finditer(r'\(scc:([^\)]+)\)', content):
                 full_match = match.group(0)
                 scc_key = match.group(1)
                 if scc_key in scc_map:
                      quoted_path = urllib.parse.quote(scc_map[scc_key])
                      replacement = "(" + URL_PREFIX + quoted_path + URL_SUFFIX +")"
                      new_content = new_content.replace(full_match, replacement)
             
             if new_content != content:
                  md_path.write_text(new_content, encoding="utf-8")

    def main():
        if not MD_DPATH.exists():
            print(f"Directory {MD_DPATH} does not exist.")
            return

        scc_map = load_scc_map()
        if not scc_map:
            print("No SCC map found or empty.")
            return

        for md in MD_DPATH.rglob("*.md"):
            process_file(md, scc_map)

    if __name__ == "__main__":
        main()

##################################################
# Private Recipes
##################################################