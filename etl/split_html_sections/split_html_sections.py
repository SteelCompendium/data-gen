import os
import sys
import shutil
import copy
import re
from lxml import html, etree

def sanitize_filename(text):
    # Convert to lowercase
    text = text.lower()
    # Replace spaces and special characters with underscores
    text = re.sub(r'[\s\-]+', '_', text)
    # Remove any invalid filename characters
    text = re.sub(r'[^\w\._-]', '', text)
    # Truncate to a reasonable length
    return text[:100]

def get_section_header_text(section_element):
    header = section_element.xpath('.//h1|.//h2|.//h3|.//h4|.//h5|.//h6')
    if header:
        return header[0].text_content()
    else:
        return None

def process_section(section_element, parent_header_text, output_dir):
    # Get the current section's header text
    current_header_text = get_section_header_text(section_element)
    if current_header_text:
        current_filename_base = current_header_text
    else:
        current_filename_base = 'section'

    # Determine whether to embed or output separately
    # If current_header_text == parent_header_text + '-1', then embed
    if parent_header_text and current_header_text == f"{parent_header_text}-1":
        # Embed the section
        # Process child sections recursively
        for child in section_element:
            if child.tag == 'section':
                process_section(child, current_header_text, output_dir)
        return

    # Determine if the section has any child sections that will be output separately
    has_separate_child_sections = False
    for child in section_element:
        if child.tag == 'section':
            child_header_text = get_section_header_text(child)
            if not (current_header_text and child_header_text == f"{current_header_text}-1"):
                has_separate_child_sections = True
                break

    # Decide whether to create a directory or just an HTML file
    if has_separate_child_sections:
        # Output as separate directory
        section_dir = os.path.join(output_dir, current_filename_base)
        os.makedirs(section_dir, exist_ok=True)
        output_path = section_dir
    else:
        # Output as a single file in the output_dir
        output_path = output_dir

    # Create the output file, named based on the header text
    output_file = os.path.join(output_path, f"{current_filename_base}.html")

    # Make a copy of the section element for output
    section_copy = copy.deepcopy(section_element)

    # Process child elements
    for child in list(section_copy):
        if child.tag == 'section':
            child_header_text = get_section_header_text(child)

            if current_header_text and child_header_text == f"{current_header_text}-1":
                # Embed the child section
                # Process the child section recursively
                process_section(child, current_header_text, output_path)
            else:
                # Remove the child section from the current section
                section_copy.remove(child)

                # Insert the name of the child section
                section_name = child_header_text if child_header_text else 'Unnamed Section'

                # Insert a link to the child section
                if has_separate_child_sections:
                    link_href = f'./{section_name}/{section_name}.html'
                else:
                    link_href = f'./{section_name}.html'
                link = html.Element('a', href=link_href)
                link.text = section_name

                # Add link to doc
                p = html.Element('p')
                p.append(link)
                section_copy.append(p)

                # Process the child section recursively
                process_section(child, current_header_text, output_path)
        else:
            # Non-section content remains in the current section
            pass

    # Write the section to the output file
    tree = etree.ElementTree(section_copy)
    tree.write(output_file, encoding='utf-8', method='html', pretty_print=True)

def main():
    if len(sys.argv) != 4:
        print("Usage: python script.py input.html xpath output_directory")
        sys.exit(1)

    input_file = sys.argv[1]
    xpath = sys.argv[2]
    output_dir = sys.argv[3]

    # Read the HTML content from file
    with open(input_file, 'r', encoding='utf-8') as f:
        html_content = f.read()

    # Parse the HTML content
    root = html.fromstring(html_content)

    # Get the root section element via XPath
    section_elements = root.xpath(xpath)
    if not section_elements:
        print(f"No elements found for XPath: {xpath}")
        sys.exit(1)
    section_element = section_elements[0]

    # Clear the output directory if it exists
    if os.path.exists(output_dir):
        shutil.rmtree(output_dir)

    # Create the output directory
    os.makedirs(output_dir, exist_ok=True)

    # Get the header text for the root section
    root_header_text = get_section_header_text(section_element)

    # Process the root section
    process_section(section_element, parent_header_text=None, output_dir=output_dir)

if __name__ == '__main__':
    main()
