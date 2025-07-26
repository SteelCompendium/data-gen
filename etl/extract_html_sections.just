log_prefix := "[JUST][extract_html_sections]"

failed_extraction_fpath := source_dir() / "../staging/failed_extractions.txt"

##################################################
# Public Recipes
##################################################

# Given a fully expanded config.yml doc, extract all the sections and apply generic metadata
# See section_config.just for info on config expectations
extract_sections config_fpath html_fpath output_dpath skip_delete="true":
    #!/usr/bin/env python3
    import yaml, subprocess, tempfile, sys
    from pathlib import Path

    cfg = yaml.safe_load(open("{{config_fpath}}"))
    out_root = Path("{{output_dpath}}")
    html = "{{html_fpath}}"

    # These will all get added to the output html as metadata
    KEYS = ["file_dpath","xpath","header_path","type", "source", "item_id", "item_name"]

    for s in cfg.get("sections", []):
        file_dpath = s.get("file_dpath") or ""
        xpath = s.get("xpath")
        if not xpath:
            print(f"Skipping section missing xpath in config: {s.get('header_path','')}", file=sys.stderr)
            continue

        ability_dir = out_root / file_dpath
        ability_dir.mkdir(parents=True, exist_ok=True)

        meta = {k: s.get(k, "") for k in KEYS}
        with tempfile.NamedTemporaryFile("w", delete=False, suffix=".yml") as tmp:
            yaml.safe_dump(meta, tmp, sort_keys=False)
            meta_path = tmp.name

        subprocess.run(["just", "extract_html_sections", "extract_section", str(ability_dir), xpath, html, "{{skip_delete}}", meta_path], check=True)

    print(f"Successfully extracted sections to '{out_root}'")
    print("See failed extractions in staging/failed_extractions.txt")


# Generate markdown files for all matches of an xpath (via html)
# if `skip_delete` is `true`, deletes the `out_dpath`
extract_section out_dpath xpath src_html_fpath skip_delete="true" metadata_yml_fpath="":
    #!/usr/bin/env bash
    set -euo pipefail
    echo >&2 ""
    echo >&2 "{{log_prefix}} Extracting '{{xpath}}'"

    if [ "{{skip_delete}}" == "true" ]; then
        rm -rf "{{out_dpath}}"
    else
        echo >&2 "    Skipping delete on dir '{{out_dpath}}'"
    fi

    just -f "{{source_file()}}" _extract_section "{{xpath}}" "{{src_html_fpath}}" "{{out_dpath}}" "{{metadata_yml_fpath}}"

##################################################
# Private Recipes
##################################################

_extract_section xpath src_html_fpath out_dpath metadata_yml_fpath:
    #!/usr/bin/env python3
    import re
    import os
    import yaml
    from lxml import etree, html

    def build_meta_block(meta_dict):
        lines = [f'  <meta name="{k}" content="{v}" />' for k, v in meta_dict.items() if v is not None]
        return "<head>\n" + "\n".join(lines) + "\n</head>\n"

    def inject_meta(section_html, meta_block):
        # If there's already a <head>, drop metas right after the opening tag.
        m = re.search(r'(<head[^>]*>)', section_html, flags=re.IGNORECASE)
        if m:
            insert_at = m.end()
            return section_html[:insert_at] + "\n" + meta_block.replace("<head>", "").rstrip("\n") + "\n" + section_html[insert_at:]
        else:
            # Prepend a brand new head block
            return meta_block + section_html

    def to_kebab_case(text):
        """Converts a string to kebab-case."""
        text = text.replace("'", "")
        text = re.sub(r'([a-z0-9])([A-Z])', r'\1-\2', text)
        text = re.sub(r'[^a-zA-Z0-9]+', '-', text)
        return text.strip('-').lower()

    # Ensure output dir exists
    os.makedirs("{{out_dpath}}", exist_ok=True)

    # Parse HTML
    with open("{{src_html_fpath}}", 'r', encoding='utf-8') as f:
        tree = html.parse(f)

    # Load metadata YAML
    if "{{metadata_yml_fpath}}" != "":
        with open("{{metadata_yml_fpath}}", 'r', encoding='utf-8') as m:
            meta = yaml.safe_load(m) or {}
    else:
        meta = {}

    # replace <p> header with h6
    p_header_pattern = re.compile(
        r'<p(?P<attrs>[^>]*)\bclass="heading"(?P<rest>[^>]*)>(?P<inner>.*?)</p>',
        re.DOTALL
    )

    # Find items
    items = tree.xpath("{{xpath}}")

    for item in items:
        # header text or first paragraph as fallback
        header = item.xpath('.//*[self::h1 or self::h2 or self::h3 or self::h4 or self::h5 or self::h6 or self::h7 or self::h8 or self::p]/text()')
        header = (header[0] if header else "item").title()

        filename = re.sub(r'\s*\(.*\)', '', ' '.join(header.split()))
        filename = filename.replace("’", "").replace("'", "").replace("…", "")
        filename = os.path.join("{{out_dpath}}", filename) + ".html"

        item_content = etree.tostring(item, pretty_print=False, method="html").decode('utf-8')

        # metadata (with item_id)
        item_meta = dict(meta)
        item_meta['item_name'] = item_meta.get('item_name') or header
        # TODO - this should move to post-extract metadata generation
        item_meta['item_id'] = item_meta.get('item_id') or to_kebab_case(header)
        item_content = inject_meta(item_content, build_meta_block(item_meta))

        # replace <p> header with h6
        item_content = p_header_pattern.sub(r'<h6\g<attrs> class="heading"\g<rest>>\g<inner></h6>', item_content)

        with open(filename, 'w', encoding='utf-8') as f_out:
            f_out.write(item_content)

    print(f'Extracted {len(items)} items.')
    if len(items) == 0:
        with open("{{failed_extraction_fpath}}", 'a', encoding='utf-8') as f_out:
            f_out.write("{{xpath}}\n")
