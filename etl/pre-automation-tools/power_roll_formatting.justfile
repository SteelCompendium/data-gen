# Usage: just run path/to/input.md path/to/output.md
# ~/code/personal/steelCompendium $ just -f data-gen/etl/pre-automation-tools/power_roll_formatting.justfile run data-gen/Rules/Draw\ Steel\ RC\ for\ Patrons.md data-gen/temp/power_rolls_formatted.md
#
# Formats 'Power Roll' sections from OCR'd markdown files.

[no-cd]
run input_md_path output_md_path:
    #!/usr/bin/env python3
    import re, sys

    def format_section(text):
        """Takes a power roll section string and returns a formatted version."""
        
        heading_part = ""
        body = text.strip()
        
        pr_marker = "Power Roll +"
        
        first_line_match = re.match(r'.*', body)
        first_line = first_line_match.group(0) if first_line_match else ""

        if pr_marker in first_line:
            match = re.match(r'^(\s*#+\s*)(.*)', first_line)
            if match:
                heading_prefix, heading_content = match.groups()
                pr_index = heading_content.find(pr_marker)
                
                # Reconstruct body from parts to avoid slicing errors
                # The content after the first line starts at body[len(first_line):]
                # but this is brittle if there are CRLF issues.
                # A safer way is to find the first newline.
                first_newline_idx = body.find('\n')
                if first_newline_idx == -1:
                    content_after_first_line = ""
                else:
                    content_after_first_line = body[first_newline_idx:]

                if pr_index > 0:
                    heading_part = (heading_prefix + heading_content[:pr_index]).strip()
                    body = heading_content[pr_index:] + content_after_first_line
                else:
                    body = heading_content + content_after_first_line

        attribute_match = re.search(r'Power Roll \+ ([^:\n]+)', body)
        attribute = attribute_match.group(1).strip() if attribute_match else ""

        # A more robust way to get tier text, ignoring all markdown noise
        temp_body = re.sub(r'#+\s*|[\n\r]\s*-\s*', ' ', body)
        temp_body = re.sub(r'\s+', ' ', temp_body)

        tier1_match = re.search(r'á(.*?)(?=é|í|\*\*Effect:|$)', temp_body, re.IGNORECASE)
        tier1 = tier1_match.group(1).strip() if tier1_match else None
        
        tier2_match = re.search(r'é(.*?)(?=í|\*\*Effect:|$)', temp_body, re.IGNORECASE)
        tier2 = tier2_match.group(1).strip() if tier2_match else None
        
        tier3_match = re.search(r'í(.*?)(?=\*\*Effect:|$)', temp_body, re.IGNORECASE)
        tier3 = tier3_match.group(1).strip() if tier3_match else None

        effect_match = re.search(r'(\*\*Effect:.*)', body, re.IGNORECASE | re.DOTALL)
        effect = None
        if effect_match:
            effect = re.sub(r'\s+', ' ', effect_match.group(1).strip())

        # Build the result
        result_parts = []
        if heading_part:
            result_parts.append(heading_part)
            result_parts.append("")

        pr_block_parts = [f"**Power Roll + {attribute}:**"]
        if tier1: pr_block_parts.append(f"- **≤11:** {tier1}")
        if tier2: pr_block_parts.append(f"- **12-16:** {tier2}")
        if tier3: pr_block_parts.append(f"- **17+:** {tier3}")
        if effect:
            if any([tier1, tier2, tier3]):
                pr_block_parts.append("")
            pr_block_parts.append(effect)
        
        result_parts.append("\n".join(pr_block_parts))
        return "\n".join(result_parts)

    def process_content(content):
        # This function finds all power roll sections and replaces them using a callback.
        # A section is defined as any text starting on a line with "Power Roll +"
        # and ending just before the next H2/H3 heading or the end of the file.
        # The lookahead is adjusted to not consume trailing whitespace.
        pattern = re.compile(
            r"^[^\n]*Power Roll \+.*?(?=\s*^(?:##|###)[^#]|\s*^####\s+(?![áéí])|\Z)",
            re.MULTILINE | re.DOTALL
        )
        
        # Find all sections first, then replace.
        # This is because a replacement could introduce a new "Power Roll +" string.
        # We can use a simple loop over matches.
        
        matches = list(pattern.finditer(content))
        if not matches:
            return content
            
        # If there are multiple "Power Roll +" sections that aren't separated by H2/H3,
        # the regex will create one big match. The format_section function isn't
        # designed to handle that. Let's assume one PR per heading section for now.
        # A better regex would be one that finds the *start* of a section.

        new_content = pattern.sub(lambda m: format_section(m.group(0)), content)
        return new_content

    with open('{{input_md_path}}', 'r', encoding='utf-8') as f:
        original_content = f.read()

    final_content = process_content(original_content)
    # Ensure single trailing newline
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

    # Ensure temp dir is clean and exists
    rm -f "$TEMP_DIR"/*.md
    mkdir -p "$TEMP_DIR"

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