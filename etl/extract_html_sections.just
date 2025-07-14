log_prefix := "[JUST][extract_html_sections]"

# Generate markdown files for all matches of an xpath (via html)
extract_section out_dpath xpath src_html_fpath skip_delete="true":
    #!/usr/bin/env bash
    set -euo pipefail
    echo >&2 ""
    echo >&2 "{{log_prefix}} Extracting '{{xpath}}'"

    if [ "{{skip_delete}}" == "true" ]; then
        rm -rf "{{out_dpath}}"
    else
        echo >&2 "    Skipping delete on dir '{{out_dpath}}'"
    fi

    just extract_html_sections _extract_section "{{xpath}}" "{{src_html_fpath}}" "{{out_dpath}}"

_extract_section xpath src_html_fpath out_dpath:
    #!/usr/bin/env python3
    import re
    import os
    from lxml import etree, html

    # Create the output directory if it doesn't exist
    os.makedirs("{{out_dpath}}", exist_ok=True)

    # Parse the HTML file
    with open("{{src_html_fpath}}", 'r', encoding='utf-8') as f:
        tree = html.parse(f)

    # Find all matching sections
    sections = tree.xpath("{{xpath}}")

    # Iterate over the sections and save each one
    for section in sections:
        # Extract the first header (h1 to h6) and clean it for the filename
        header = section.xpath('.//*[self::h1 or self::h2 or self::h3 or self::h4 or self::h5 or self::h6 or self::h7 or self::h8]/text()')[0]
        header = header.title()
        filename = re.sub('\\s*\\(.*\\)', '', ' '.join(header.split())).replace("’", "").replace("'","").replace("…","")
        filename = os.path.join("{{out_dpath}}", filename)

        # Get the section content as HTML
        section_content = etree.tostring(section, pretty_print=False, method="html").decode('utf-8')

        # Save as HTML
        filename += ".html"
        with open(filename, 'w', encoding='utf-8') as f_out:
            f_out.write(section_content)

    print(f'Extracted {len(sections)} sections.')
