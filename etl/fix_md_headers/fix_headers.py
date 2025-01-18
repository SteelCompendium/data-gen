#!/usr/bin/env python3
import sys
import re
import unicodedata
from difflib import get_close_matches

def main():
    if len(sys.argv) < 4:
        print(f"Usage: {sys.argv[0]} <bookmarks.txt> <original.md> <corrected.md>")
        sys.exit(1)

    bookmarks_file = sys.argv[1]
    input_md_file = sys.argv[2]
    output_md_file = sys.argv[3]

    # 1. Parse bookmarks.txt -> (text, level) in order
    #    Then store them in a dict:  heading_text -> [level1, level2, ...]
    bookmarks_map = build_bookmarks_map(bookmarks_file)

    # We'll track how many times we've used each heading text so far
    usage_count = {}

    # 2. Read the Markdown, fix headings
    with open(input_md_file, "r", encoding="utf-8", errors="replace") as fin, \
            open(output_md_file, "w", encoding="utf-8", errors="replace") as fout:

        for line in fin:
            # Check if this line is a heading of the form:
            # ## Some heading text
            match = re.match(r"^(#+)\s+(.*)$", line)
            if match:
                old_hashes = match.group(1)
                heading_text = match.group(2).strip()

                # Clean the heading text to compare with bookmarks
                heading_clean = clean_text(heading_text).lower().strip()

                # Attempt exact match in bookmarks_map
                if heading_clean in bookmarks_map:
                    count = usage_count.get(heading_clean, 0)
                    levels_list = bookmarks_map[heading_clean]

                    if count < len(levels_list):
                        # We still have an unused level in the list
                        desired_level = levels_list[count]
                    else:
                        # We've used up all known levels for this heading text;
                        # fall back to the *last* known level
                        desired_level = levels_list[-1]

                    usage_count[heading_clean] = count + 1

                    new_hashes = "#" * desired_level
                    new_line = f"{new_hashes} {heading_text}\n"
                    fout.write(new_line)
                else:
                    # No match in bookmarks_map, just write out as-is
                    fout.write(line)
            else:
                # Not a heading line
                fout.write(line)

    print(f"Done. Wrote corrected headings to {output_md_file}.")


def build_bookmarks_map(bookmarks_file):
    """
    Read pdfcpu bookmarks.txt output, detect indentation -> heading level.
    Build a dict that maps normalized heading text to a *list* of levels
    in the order they appear in the bookmarks. E.g.:
       {
         'heroic advancement': [1, 2],
         'adjusted xp advancement': [3, 4],
         ...
       }
    """
    from collections import defaultdict

    bookmarks_map = defaultdict(list)

    with open(bookmarks_file, "r", encoding="utf-8", errors="replace") as f:
        for line in f:
            line = line.rstrip("\n\r")
            leading_spaces = len(line) - len(line.lstrip(" "))
            # e.g. 4 spaces = H2, 8 spaces = H3, etc.
            level = (leading_spaces // 4) + 1
            if level < 1:
                level = 1

            text = line.lstrip()
            text = clean_text(text)
            cleaned = text.lower().strip()

            bookmarks_map[cleaned].append(level)

    return dict(bookmarks_map)


def clean_text(text):
    """
    Remove/normalize odd control characters and unify weird punctuation/dashes
    (especially important for headings like “2nd–Level” which uses an en dash).
    """
    # Normalize Unicode forms
    text = unicodedata.normalize("NFC", text)

    # Remove control characters
    filtered_chars = []
    for ch in text:
        cat = unicodedata.category(ch)
        if not cat.startswith("C"):
            filtered_chars.append(ch)
    text = "".join(filtered_chars)

    # Replace funky dashes/apostrophes with ASCII equivalents
    text = text.replace("–", "-")
    text = text.replace("—", "-")
    text = text.replace("’", "'")
    # Add more replacements as needed:
    # text = text.replace("“", '"').replace("”", '"')

    return text


if __name__ == "__main__":
    main()
