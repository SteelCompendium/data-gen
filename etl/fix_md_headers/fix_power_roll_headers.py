#!/usr/bin/env python3
import sys
import re

# Compile a pattern that matches:
#   - Start of line
#   - 1-6 '#' characters (the heading), plus optional spaces
#   - Followed by any text that must include "Power Roll +"
pattern = re.compile(r'^(#{1,6}\s+)(.*Power Roll \+.*)$')

def process_markdown_lines(lines):
    for line in lines:
        match = pattern.match(line)
        if match:
            # Print only the second group (the content after removing heading markers)
            new_line = match.group(2)
            yield new_line
        else:
            yield line

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: fix_power_roll_headers.py <input-file>", file=sys.stderr)
        sys.exit(1)
    input_file = sys.argv[1]

    # Read entire file as list of lines
    with open(input_file, "r", encoding="utf-8") as f:
        lines = f.readlines()

    # Process them
    processed_lines = process_markdown_lines(lines)

    # Overwrite the same file
    with open(input_file, "w", encoding="utf-8") as f:
        f.writelines(processed_lines)
