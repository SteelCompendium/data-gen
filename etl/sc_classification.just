# Justfile module expected to be named "sc_classification"

##################################################
# Constants and env vars
##################################################

##################################################
# Public Recipes
##################################################

# generates classification fields in the frontmatter of all markdown files in the directory (recursive)
# generates frontmatter `scdc`, `scc`, and `item_index`
# Needs frontmatter `type`, `source`, and `item_id`
gen_frontmatter md_dpath state_json_fpath scc_to_path_json_fpath:
    #!/usr/bin/env python3
    import json
    import sys
    import frontmatter
    from pathlib import Path
    from typing import Dict

    STATE_FILE = Path("{{state_json_fpath}}")
    SCC_TO_PATH_JSON_FILE = Path("{{scc_to_path_json_fpath}}")

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

    def load_scc_map():
        if SCC_TO_PATH_JSON_FILE.exists():
            return json.loads(SCC_TO_PATH_JSON_FILE.read_text())
        return {}

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

    def process_file(md_path: Path, state, scc_map):
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
        scc_val = f"{src}:{'.'.join(type_comps)}:{itm}"
        post["scdc"] = [f"{source_id}:{type_id}:{cnt_id}"]
        post["scc"] = [scc_val]
        post["item_index"] = f"{cnt_id}"

        # 5) update scc mapping file
        file_dpath = post.get("file_dpath")
        file_basename = post.get("file_basename")
        path_prefix = ""
        match src:
            case "mcdm.heroes.v1":
                path_prefix = "Rules/"
            case "mcdm.monsters.v1":
                path_prefix = "Bestiary/"
            case _:
                sys.exit("MD file has unknown source: " + src + ". Expected something like mcdm.heroes.v1")
        path_value = path_prefix + file_dpath + "/" + file_basename
        if scc_val in scc_map:
            sys.exit("Adding scc entry for '" + scc_val + "' with value '" + path_value + "' but there is already a value: " + scc_map[scc_val])
        if file_dpath:
            scc_map[scc_val] = path_value

        # 6) overwrite the file in place
        md_path.write_text(frontmatter.dumps(post), encoding="utf-8")

    def scan_directory(root_dir):
        root = Path(root_dir)
        state = load_state()
        scc_map = load_scc_map()
        for md in root.rglob("*.md"):
            process_file(md, state, scc_map)
        save_state(state)
        SCC_TO_PATH_JSON_FILE.write_text(json.dumps(scc_map, indent=2))

    # Pass md_dpath (string) straight in; scan_directory() wraps it in Path()
    scan_directory("{{md_dpath}}")
