import os
import re
import sys
import inflect

# List of notes that should NOT be linked TO in other files
titles_to_skip = [
    "Ward",  # All the caster kits have "ward" in them, but there is a "ward" complication
    "index"  # The class ability notes (index.md) should not be linked anywhere
]

# These folders will not be linked TO AND FROM
folders_to_skip = [
    "Rules", # keep the rules pure.  The "linked" rules go in a temp folder called Formatted
    "Cultures", # Nothing should link TO these (headers), but the other way makes a lot of bad links
    "Skills", # Nothing should link TO these (headers), but the other way makes a lot of bad links
    "util", # shouldnt need to link anything in here
    "Negotiation/Motivations and Pitfalls", # "Power" is one of the motivations which will link to every Power Roll
    # TODO - I do want to auto-link these files, need to update some regexes below
    "Classes" # Classes has links already predefined that are in the []() form, skip it
]

p = inflect.engine()

def find_markdown_files(directory):
    """Find all markdown files in a given directory."""
    markdown_files = []

    for root, _, files in os.walk(directory):
        def should_skip():
            for to_skip in folders_to_skip:
                if f"{directory}/{to_skip}" in root:
                    print(f"Skipping auto-link on {root} ({to_skip})")
                    return True
            return False
        if should_skip():
            continue

        for file in files:
            if file.endswith(".md"):
                markdown_files.append(os.path.join(root, file))
    return markdown_files

def get_note_titles(markdown_files):
    """Extract note titles (without extension) from a list of markdown files."""
    note_titles = set()
    for file in markdown_files:
        title = os.path.basename(file).replace(".md", "")
        if title not in titles_to_skip:
            note_titles.add(title)
    return note_titles

def read_file_with_encoding_fallback(file_path):
    """Read file with a fallback for encoding issues."""
    try:
        with open(file_path, 'r', encoding='utf-8') as file:
            return file.read()
    except UnicodeDecodeError:
        with open(file_path, 'r', encoding='ISO-8859-1') as file:
            return file.read()

def remove_links_in_headers_and_frontmatter(content):
    lines = content.split('\n')
    new_lines = []
    in_frontmatter = False

    # Regex pattern to find Obsidian-style links [[FileName|alias]] or [[FileName]]
    link_pattern = re.compile(r'\[\[([^\]|]+)(\|([^\]]+))?\]\]')

    for line in lines:
        stripped_line = line.lstrip()

        # Check for frontmatter start/end
        if stripped_line.startswith('---'):
            # Toggle frontmatter state
            in_frontmatter = not in_frontmatter
            new_lines.append(line)
            continue

        if in_frontmatter or stripped_line.startswith('#'):
            # Remove Obsidian links from this line
            def replace_link(match):
                # If there's an alias, use it; else, use the file name
                alias = match.group(3) if match.group(3) else match.group(1)
                return alias

            line = link_pattern.sub(replace_link, line)

        new_lines.append(line)
    return '\n'.join(new_lines)

def update_unlinked_references_in_file(file_path, note_titles):
    """Update unlinked references in a markdown file by converting them to Obsidian links."""
    try:
        content = read_file_with_encoding_fallback(file_path)
        original_content = content

        # Build a mapping of forms to titles and create a regex pattern
        form_to_title = {}

        for title in note_titles:
            # Don't add links to self
            if title.lower() == os.path.splitext(os.path.basename(file_path))[0].lower():
                continue

            forms = set()
            forms.add(title)

            # Generate singular and plural forms using inflect
            singular_form = p.singular_noun(title)
            if singular_form and singular_form.lower() != title.lower():
                forms.add(singular_form)

            plural_form = p.plural(title)
            if plural_form and plural_form.lower() != title.lower():
                forms.add(plural_form)

            # Add the forms to the dict
            for form in forms:
                form_lower = form.lower()
                if form_lower not in form_to_title:
                    form_to_title[form_lower] = title  # Map form to the original title

        # Create a regex pattern that matches any of the forms
        forms = sorted(form_to_title.keys(), key=len, reverse=True)
        pattern = re.compile(r'(?<![\[\|\w])({})(?![\]\|\w])'.format('|'.join(map(re.escape, forms))), flags=re.IGNORECASE)

        # Split content into lines for line-by-line processing
        lines = content.split('\n')
        in_frontmatter = False

        for i in range(len(lines)):
            line = lines[i]

            # Skip processing in frontmatter and headers
            if line.lstrip().startswith('---'):
                # Toggle frontmatter state
                in_frontmatter = not in_frontmatter
                lines[i] = line
                continue
            if in_frontmatter or line.lstrip().startswith('#'):
                lines[i] = line
                continue

            # Check if the line is a table row
            is_table_row = line.strip().startswith('|')

            # Find markdown links in the line
            link_spans = [(m.start(), m.end()) for m in re.finditer(r'\[.*?\]\(.*?\)', line)]

            # Get non-link spans
            non_link_spans = []
            last_end = 0
            for start, end in sorted(link_spans):
                if last_end < start:
                    non_link_spans.append((last_end, start))
                last_end = end
            if last_end < len(line):
                non_link_spans.append((last_end, len(line)))

            # Create spans with flags
            spans = []
            for start, end in link_spans:
                spans.append((start, end, 'link'))
            for start, end in non_link_spans:
                spans.append((start, end, 'non_link'))

            # Sort spans
            spans.sort(key=lambda x: x[0])

            # Process spans
            new_line = ''
            for span in spans:
                start, end, span_type = span
                segment = line[start:end]

                if span_type == 'link':
                    # Append the segment unmodified
                    new_line += segment
                else:
                    # Apply replacements to segment
                    def replace_with_link(match):
                        found_text = match.group(0)
                        form_lower = found_text.lower()

                        # Get the corresponding title
                        title = form_to_title.get(form_lower, None)

                        if title is None:
                            return found_text

                        # Determine the replacement link
                        if found_text != title:
                            # If the found text case doesn't match the title, create an alias
                            link = f'[[{title}|{found_text}]]'
                        else:
                            link = f'[[{title}]]'
                        if is_table_row:
                            # Escape '|' in link if inside a table row
                            link = link.replace('|', '\\|')
                        return link

                    segment = pattern.sub(replace_with_link, segment)
                    new_line += segment

            # Update the line
            lines[i] = new_line

        # Reconstruct content from processed lines
        content = '\n'.join(lines)

        # Remove links in headers and frontmatter
        content = remove_links_in_headers_and_frontmatter(content)

        # TODO - Rewriting all the files for now to force utf-8 encoding.  The below code should be used to optimize
        #  when encoding isnt an issue.  Its something in the Perks section, extract_html_sections
        with open(file_path, 'w', encoding='utf-8') as file:
            file.write(content)
        print(f"Updated links in file: {file_path}")

        # # Only write changes if there are any updates
        # if content != original_content:
        #     with open(file_path, 'w', encoding='utf-8') as file:
        #         file.write(content)
        #     print(f"Updated links in file: {file_path}")
    except Exception as e:
        print(f"Error processing file {file_path}: {e}")


def update_all_notes(directory):
    """Update all notes in the Obsidian vault directory."""
    markdown_files = find_markdown_files(directory)
    note_titles = get_note_titles(markdown_files)

    for file_path in markdown_files:
        update_unlinked_references_in_file(file_path, note_titles)
    print(f"Links updated successfully in directory: {directory}")

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python obs-auto-linker.py <directory_path>")
        sys.exit(1)

    vault_directory = sys.argv[1]

    if not os.path.isdir(vault_directory):
        print(f"Error: The directory {vault_directory} does not exist.")
        sys.exit(1)

    update_all_notes(vault_directory)
