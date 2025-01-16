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

    # 1. Parse bookmarks.txt -> list of (text, level), in order
    bookmarks = parse_bookmarks(bookmarks_file)

    # Build a dict of heading_text -> list of levels in the order they appear
    bookmarks_map = {}
    for text, level in bookmarks:
        cleaned = clean_text(text).lower().strip()
        bookmarks_map.setdefault(cleaned, []).append(level)

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
                    # If we still have an unused level for this heading
                    if count < len(bookmarks_map[heading_clean]):
                        desired_level = bookmarks_map[heading_clean][count]
                        usage_count[heading_clean] = count + 1

                        new_hashes = "#" * desired_level
                        new_line = f"{new_hashes} {heading_text}\n"
                        fout.write(new_line)
                    else:
                        # We've already used all known levels.
                        # Fall back to the last known or just leave it.
                        # In this example, we'll leave it as is:
                        fout.write(line)
                else:
                    # Optionally do fuzzy matching if needed
                    # possible_matches = get_close_matches(
                    #     heading_clean,
                    #     bookmarks_map.keys(),
                    #     n=1,
                    #     cutoff=0.8
                    # )
                    # if possible_matches:
                    #     best_match = possible_matches[0]
                    #     count = usage_count.get(best_match, 0)
                    #     if count < len(bookmarks_map[best_match]):
                    #         desired_level = bookmarks_map[best_match][count]
                    #         usage_count[best_match] = count + 1
                    #         new_hashes = "#" * desired_level
                    #         new_line = f"{new_hashes} {heading_text}\n"
                    #         fout.write(new_line)
                    #     else:
                    #         fout.write(line)
                    # else:
                    fout.write(line)
            else:
                # Not a heading line
                fout.write(line)

    print(f"Done. Wrote corrected headings to {output_md_file}.")


def parse_bookmarks(bookmarks_file):
    """
    Read pdfcpu bookmarks.txt output, detect indentation -> heading level,
    return a list of (text, level) in the order they appear.
    """
    results = []
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
            results.append((text, level))
    return results

def clean_text(text):
    """
    Remove/normalize odd control characters and do any custom replacements
    needed for matching.
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

    # You can also do ASCII punctuation replacements if needed
    # e.g. text = text.replace("…", "...").replace("“", '"').replace("”", '"')
    return text


if __name__ == "__main__":
    main()
