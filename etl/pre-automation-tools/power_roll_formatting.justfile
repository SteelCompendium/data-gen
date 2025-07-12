# Usage: just run path/to/input.md path/to/output.md
# ~/code/personal/steelCompendium $ just -f data-gen/etl/pre-automation-tools/power_roll_formatting.justfile run data-gen/Rules/Draw\ Steel\ RC\ for\ Patrons.md data-gen/temp/power_rolls_formatted.md
#
# Formats 'Power Roll' sections from OCR'd markdown files.

[no-cd]
run input_md_path output_md_path:
    #!/usr/bin/env python3
    import re, sys

    with open('{{input_md_path}}', 'r', encoding='utf-8') as f:
        content = f.read()

    new_content_parts = []
    last_end = 0

    # This regex finds all power roll sections. It captures:
    # 1. Any text on the same line preceding "Power Roll..." (for inline cases)
    # 2. The attribute (e.g., "Might", "Agility")
    # 3. The body of the power roll text itself
    # The lookahead at the end stops the match before the next heading or ** block.
    pattern = re.compile(
        r'^(.*?)(?:####\s*)?Power Roll \+ (\w+):(.*?)(?=^#|^\*\*|\Z)',
        re.MULTILINE | re.DOTALL
    )

    for match in pattern.finditer(content):
        # Append the content since the last match
        new_content_parts.append(content[last_end:match.start()])

        preceding_text = match.group(1)
        attribute = match.group(2)
        body = match.group(3)

        # If there was text before "Power Roll" on the line, it's an inline case.
        # Add that text back, ensuring it's on its own line.
        if preceding_text.strip():
            new_content_parts.append(preceding_text.strip() + "\n\n")

        # Normalize the body: remove heading markers, newlines, list markers, and collapse spaces.
        body = re.sub(r'#+\s*', '', body)
        cleaned_body = re.sub(r'\s+', ' ', re.sub(r'\n\s*-\s*|\n', ' ', body)).strip()

        tier1_text, tier2_text, tier3_text = None, None, None
        tier1_match = re.search(r'á(.*?)(?=é|í|$)', cleaned_body)
        if tier1_match: tier1_text = tier1_match.group(1).strip()
        tier2_match = re.search(r'é(.*?)(?=í|$)', cleaned_body)
        if tier2_match: tier2_text = tier2_match.group(1).strip()
        tier3_match = re.search(r'í(.*?$)', cleaned_body)
        if tier3_match: tier3_text = tier3_match.group(1).strip()

        # Build the formatted output string
        formatted_block = [f"**Power Roll + {attribute}:**"]
        if tier1_text: formatted_block.append(f"- **≤11:** {tier1_text}")
        if tier2_text: formatted_block.append(f"- **12-16:** {tier2_text}")
        if tier3_text: formatted_block.append(f"- **17+:** {tier3_text}")
        
        new_content_parts.append("\n".join(formatted_block))

        last_end = match.end()

    # Append any remaining content after the last match
    new_content_parts.append(content[last_end:])

    final_content = "".join(new_content_parts)

    # Ensure there's a single trailing newline
    final_content = final_content.rstrip() + '\n'

    with open('{{output_md_path}}', 'w', encoding='utf-8') as f:
        f.write(final_content)


[no-cd]
test:
    #!/usr/bin/env bash
    set -euo pipefail

    INPUT_DIR="data-gen/etl/pre-automation-tools/power_roll_formatting/input"
    EXPECTED_DIR="data-gen/etl/pre-automation-tools/power_roll_formatting/output"
    TEMP_DIR="data-gen/temp/power_roll_test_output"

    # Ensure temp dir is clean
    rm -f "$TEMP_DIR"/*.md

    for input_file in "$INPUT_DIR"/*.md; do
        filename=$(basename "$input_file")
        expected_file="$EXPECTED_DIR/$filename"
        temp_file="$TEMP_DIR/$filename"

        echo "Testing $filename..."
        if ! just -f {{justfile()}} run "$input_file" "$temp_file"; then
            echo "TEST FAILED: The 'run' recipe failed for $filename"
            exit 1
        fi

        if ! diff -u --strip-trailing-cr "$expected_file" "$temp_file"; then
            echo "TEST FAILED: Output did not match expected for $filename."
            exit 1
        fi
    done

    echo "All tests passed!"
