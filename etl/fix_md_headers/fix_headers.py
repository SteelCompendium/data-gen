#!/usr/bin/env python3
import sys
import re
import unicodedata
from difflib import get_close_matches

def main():
    if len(sys.argv) < 4:
        print(f"Usage: {sys.argv[0]} <bookmarks.txt> <original.md> <corrected.md>")
        print("Example:")
        print(f"  {sys.argv[0]} bookmarks.txt original.md corrected.md")
        sys.exit(1)

    bookmarks_file = sys.argv[1]
    input_md_file = sys.argv[2]
    output_md_file = sys.argv[3]

    # 1. Parse bookmarks.txt -> list of (text, level)
    bookmarks = parse_bookmarks(bookmarks_file)

    # Turn that list into a dict: {cleaned_text_lower: level}
    # But note that repeated headings could collide in a dict!
    # We'll handle that by storing a list of possible levels if repeated headings appear.
    bookmarks_map = {}
    for text, level in bookmarks:
        cleaned = clean_text(text).lower().strip()
        if cleaned not in bookmarks_map:
            bookmarks_map[cleaned] = []
        bookmarks_map[cleaned].append(level)

    # 2. Read the Markdown, fix headings
    with open(input_md_file, "r", encoding="utf-8", errors="replace") as fin, \
            open(output_md_file, "w", encoding="utf-8", errors="replace") as fout:

        for line in fin:
            # Check if this line is a heading of the form:
            # ## Some heading text
            # We'll capture the '#' part and the heading text separately.
            match = re.match(r"^(#+)\s+(.*)$", line)
            if match:
                # Current heading info
                old_hashes = match.group(1)
                heading_text = match.group(2).strip()

                # Clean the heading text to compare with bookmarks
                heading_clean = clean_text(heading_text).lower().strip()

                if heading_clean in bookmarks_map:
                    # Use the first (or last) matching level found in bookmarks
                    # If the same heading text appears multiple times in bookmarks,
                    # we might choose the first or the average or something else.
                    # Here we just pick the first for simplicity.
                    desired_level = bookmarks_map[heading_clean][0]

                    # Construct the correct heading
                    new_hashes = "#" * desired_level
                    new_line = f"{new_hashes} {heading_text}\n"
                    fout.write(new_line)
                else:
                    # Optionally do fuzzy matching if you want:
                    #
                    # possible_matches = get_close_matches(heading_clean, bookmarks_map.keys(), n=1, cutoff=0.8)
                    # if possible_matches:
                    #     best_match = possible_matches[0]
                    #     desired_level = bookmarks_map[best_match][0]
                    #     new_hashes = "#" * desired_level
                    #     new_line = f"{new_hashes} {heading_text}\n"
                    #     fout.write(new_line)
                    # else:
                    #     # No match, just write original
                    #     fout.write(line)
                    #
                    # For now, if no exact match, we leave line unchanged:
                    fout.write(line)
            else:
                # Not a heading line, write it as-is
                fout.write(line)

    print(f"Done. Wrote corrected headings to {output_md_file}.")

def parse_bookmarks(bookmarks_file):
    """
    Read the pdfcpu bookmarks.txt output, detect indentation -> heading level,
    return a list of (text, level).
    """
    results = []
    with open(bookmarks_file, "r", encoding="utf-8", errors="replace") as f:
        for line in f:
            line = line.rstrip("\n\r")
            # Count leading spaces
            leading_spaces = len(line) - len(line.lstrip(" "))
            # infer heading level. e.g. every 4 spaces = +1 level
            level = (leading_spaces // 4) + 1
            if level < 1:
                level = 1
            text = line.lstrip()
            # Clean up weird characters in the raw text from bookmarks
            text = clean_text(text)
            # Store
            results.append((text, level))
    return results

def clean_text(text):
    """
    Remove/normalize odd control characters and do any
    custom replacements you'd like.
    """
    # Normalize to NFC form
    text = unicodedata.normalize("NFC", text)

    # Remove control characters or non-printable characters:
    filtered_chars = []
    for ch in text:
        cat = unicodedata.category(ch)
        # skip control characters (Cc) or other non-printables
        if not cat.startswith("C"):
            filtered_chars.append(ch)

    text = "".join(filtered_chars)

    # Optionally replace “smart” punctuation with ASCII
    # text = text.replace("…", "...").replace("“", '"').replace("”", '"')
    # text = text.replace("‘", "'").replace("’", "'").replace("—", "-").replace("–", "-")

    return text


if __name__ == "__main__":
    main()
