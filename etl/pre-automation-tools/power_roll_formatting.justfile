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
    in_power_roll_section = False
    power_roll_lines = []

    for line in content.splitlines():
        if "Power Roll +" in line and not in_power_roll_section:
            # If we were in a section, process it before starting a new one
            if power_roll_lines:
                # Process the collected power roll section
                attribute_match = re.search(r'Power Roll \+ (\w+)', power_roll_lines[0])
                attribute = attribute_match.group(1) if attribute_match else ""
                
                body = "\n".join(power_roll_lines)
                
                effect_match = re.search(r'(\*\*Effect:.*)', body, re.IGNORECASE | re.DOTALL)
                effect_text_cleaned = None
                if effect_match:
                    effect_text_raw = effect_match.group(1).strip()
                    effect_text_cleaned = re.sub(r'\s+', ' ', effect_text_raw).strip()
                    body = body[:effect_match.start()]

                cleaned_body = re.sub(r'\s+', ' ', re.sub(r'\n\s*-\s*|\n', ' ', body)).strip()

                tier1_text, tier2_text, tier3_text = None, None, None
                tier1_match = re.search(r'á(.*?)(?=é|í|$)', cleaned_body)
                if tier1_match: tier1_text = tier1_match.group(1).strip()
                tier2_match = re.search(r'é(.*?)(?=í|$)', cleaned_body)
                if tier2_match: tier2_text = tier2_match.group(1).strip()
                tier3_match = re.search(r'í(.*?$)', cleaned_body)
                if tier3_match: tier3_text = tier3_match.group(1).strip()

                formatted_block = [f"**Power Roll + {attribute}:**"]
                if tier1_text: formatted_block.append(f"- **≤11:** {tier1_text}")
                if tier2_text: formatted_block.append(f"- **12-16:** {tier2_text}")
                if tier3_text: formatted_block.append(f"- **17+:** {tier3_text}")
                
                if effect_text_cleaned:
                    if any([tier1_text, tier2_text, tier3_text]):
                        formatted_block.append("")
                    formatted_block.append(effect_text_cleaned)
                
                new_content_parts.append("\n".join(formatted_block))
                
                # Reset for next section
                power_roll_lines = []

            in_power_roll_section = True
            power_roll_lines.append(line)
        elif in_power_roll_section:
            power_roll_lines.append(line)
        else:
            new_content_parts.append(line)

    # Process any remaining power roll section at the end of the file
    if in_power_roll_section and power_roll_lines:
        attribute_match = re.search(r'Power Roll \+ (\w+)', power_roll_lines[0])
        attribute = attribute_match.group(1) if attribute_match else ""
        
        body = "\n".join(power_roll_lines)
        
        effect_match = re.search(r'(\*\*Effect:.*)', body, re.IGNORECASE | re.DOTALL)
        effect_text_cleaned = None
        if effect_match:
            effect_text_raw = effect_match.group(1).strip()
            effect_text_cleaned = re.sub(r'\s+', ' ', effect_text_raw).strip()
            body = body[:effect_match.start()]

        cleaned_body = re.sub(r'\s+', ' ', re.sub(r'\n\s*-\s*|\n', ' ', body)).strip()

        tier1_text, tier2_text, tier3_text = None, None, None
        tier1_match = re.search(r'á(.*?)(?=é|í|$)', cleaned_body)
        if tier1_match: tier1_text = tier1_match.group(1).strip()
        tier2_match = re.search(r'é(.*?)(?=í|$)', cleaned_body)
        if tier2_match: tier2_text = tier2_match.group(1).strip()
        tier3_match = re.search(r'í(.*?$)', cleaned_body)
        if tier3_match: tier3_text = tier3_match.group(1).strip()

        formatted_block = [f"**Power Roll + {attribute}:**"]
        if tier1_text: formatted_block.append(f"- **≤11:** {tier1_text}")
        if tier2_text: formatted_block.append(f"- **12-16:** {tier2_text}")
        if tier3_text: formatted_block.append(f"- **17+:** {tier3_text}")
        
        if effect_text_cleaned:
            if any([tier1_text, tier2_text, tier3_text]):
                formatted_block.append("")
            formatted_block.append(effect_text_cleaned)
        
        new_content_parts.append("\n".join(formatted_block))

    final_content = "\n".join(new_content_parts)
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
