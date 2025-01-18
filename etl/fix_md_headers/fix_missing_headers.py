#!/usr/bin/env python3
import re
import sys

def extract_parenthetical_suffix(line):
    """
    If the line ends with parentheses, return what's inside them.
    Example: "BLESSING OF INSIGHT (5 PIETY)" -> "5 PIETY"
    Otherwise, return None.
    """
    # Strip trailing whitespace first:
    line = line.strip()

    # Look for something of the form (...) at the end of the string
    match = re.search(r'\(([^)]*)\)\s*$', line)
    if match:
        return match.group(1).strip()
    return None

def is_all_caps(line):
    """
    Return True if:
     - After removing non-alphabetic characters, there's at least one character
     - All those alphabetic characters are uppercase
     - And the original line does NOT contain a pipe character '|'
    This prevents table rows from matching as headings.
    """
    # If the line has a '|' anywhere, automatically return False
    if '|' in line:
        return False

    alpha_only = re.sub(r'[^A-Za-z]', '', line)
    if not alpha_only:  # empty after removing punctuation/numbers?
        return False

    return alpha_only.isupper()

def process_markdown_lines(lines):
    heading_regex = re.compile(r'^(#+)\s+(.*)$')
    last_heading_level = 0
    last_heading_text = None

    for line in lines:
        stripped = line.strip()

        # 1) If this line is already a heading (e.g. "##### Something")
        match = heading_regex.match(stripped)
        if match:
            hashes, text = match.groups()
            level = len(hashes)  # e.g. 5 for "#####"
            last_heading_level = level
            last_heading_text = text
            yield line  # Use it as-is
            continue

        # 2) If it's all-caps (and doesn't contain '|'), treat it as a heading
        if is_all_caps(stripped):
            # Default assumption: one level deeper than the last heading
            # but not beyond h6
            new_level = min(last_heading_level + 1, 6) if last_heading_level else 1

            # If it shares the same parenthetical suffix as the last heading,
            # then assume it's the same level.
            current_suffix = extract_parenthetical_suffix(stripped)
            last_suffix = extract_parenthetical_suffix(last_heading_text or "")
            if current_suffix and current_suffix == last_suffix:
                new_level = last_heading_level if last_heading_level else 1

            new_line = f"{'#' * new_level} {stripped}\n"
            yield new_line

            # Update context
            last_heading_level = new_level
            last_heading_text = stripped
            continue

        # 3) Otherwise, it's a normal line
        yield line

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: fix_missing_headers.py <input-file>", file=sys.stderr)
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
