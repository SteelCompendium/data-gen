# Justfile module expected to be named "frontmatter_ids"

##################################################
# Constants and env vars
##################################################

##################################################
# Public Recipes
##################################################

gen_frontmatter md_dpath state_json_fpath:
    #!/usr/bin/env python3
    import json
    import frontmatter
    from pathlib import Path
    from typing import Dict

    STATE_FILE = Path("{{state_json_fpath}}")

    def load_state():
        if STATE_FILE.exists():
            s = json.loads(STATE_FILE.read_text())
            # migrate old single‐tree schema, if present
            if "tree" in s:
                s["type_tree"] = s.pop("tree")
                s["source_tree"] = {}
            # ensure all top‐level keys exist
            s.setdefault("source_tree", {})
            s.setdefault("type_tree", {})
            s.setdefault("counters", {})
            return s
        return {"source_tree": {}, "type_tree": {}, "counters": {}}

    def save_state(state):
        STATE_FILE.write_text(json.dumps(state, indent=2))

    def get_or_assign_ids(tree: Dict, components: [str]) -> [int]:
        """
        Walks `tree`, assigning a new "_id" for any missing
        component, and returns the list of _id's.
        """
        ids = []
        node = tree
        for comp in components:
            if comp not in node:
                next_id = 1 + max(
                    (node[k]["_id"] for k in node if node[k].get("_id") is not None),
                    default=0
                )
                node[comp] = {"_id": next_id, "_children": {}}
            ids.append(node[comp]["_id"])
            node = node[comp]["_children"]
        return ids

    def process_file(md_path: Path, state):
        post = frontmatter.load(md_path)
        src = post.get("source")  # e.g. "mcdm.heroes.v1"
        typ = post.get("type")    # e.g. "heroes/introduction/…"
        itm = post.get("item_id")    # e.g. "heroes/introduction/…"
        if not src or not typ:
            return

        # 1) build source-id from the dot‑path
        src_comps = src.split(".")
        src_ids = get_or_assign_ids(state["source_tree"], src_comps)
        source_id = ".".join(str(i) for i in src_ids)

        # 2) build type-id from the slash‑path
        type_comps = typ.split("/")
        type_ids = get_or_assign_ids(state["type_tree"], type_comps)
        type_id = ".".join(str(i) for i in type_ids)

        # 3) bump the item counter for this exact type
        full_type_path = "/".join(type_comps)
        cnt = state["counters"].get(full_type_path, 0) + 1
        state["counters"][full_type_path] = cnt

        # 4) emit final id
        cnt_id = str(cnt).zfill(2)
        post["scdc"] = f"{source_id}:{type_id}:{cnt_id}"
        post["scc"] = f"{src}:{'.'.join(type_comps)}:{itm}"

        # 5) overwrite the file in place
        md_path.write_text(frontmatter.dumps(post), encoding="utf-8")

    def scan_directory(root_dir):
        root = Path(root_dir)
        state = load_state()
        for md in root.rglob("*.md"):
            process_file(md, state)
        save_state(state)

    # Pass md_dpath (string) straight in; scan_directory() wraps it in Path()
    scan_directory("{{md_dpath}}")
