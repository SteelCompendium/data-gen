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
    header = section_element.xpath('./h1|./h2|./h3|./h4|./h5|./h6')
    if header:
        return header[0].text_content().strip()
    else:
        return None

def get_section_identifier(section_element):
    section_id = section_element.get('id')
    if section_id:
        return sanitize_filename(section_id)
    else:
        header_text = get_section_header_text(section_element)
        if header_text:
            return sanitize_filename(header_text)
        else:
            return 'section'

def should_embed(section_element):
    # Check if the section has only one child section
    children = list(section_element)
    child_sections = [child for child in children if child.tag == 'section']
    return len(child_sections) == 1

def process_section(section_element, output_dir):
    # Get the current section's identifier
    current_identifier = get_section_identifier(section_element)
    current_filename_base = current_identifier

    # Decide whether to embed child sections
    children = list(section_element)
    child_sections = [child for child in children if child.tag == 'section']

    # Determine if we should embed the child section
    if should_embed(section_element):
        # The parent section will be output with the embedded child section
        # Process child sections recursively
        for child in child_sections:
            process_section(child, output_dir)
    else:
        has_separate_child_sections = bool(child_sections)
        output_path = os.path.join(output_dir, current_filename_base) if has_separate_child_sections else output_dir

        # Create the output directory if needed
        os.makedirs(output_path, exist_ok=True)

        # Make a copy of the section element for output
        section_copy = copy.deepcopy(section_element)

        # Process child elements
        for child in list(section_copy):
            if child.tag == 'section':
                section_copy.remove(child)
                child_identifier = get_section_identifier(child)
                section_name = child_identifier
                if has_separate_child_sections:
                    link_href = f'./{section_name}/{section_name}.html'
                else:
                    link_href = f'./{section_name}.html'
                link = html.Element('a', href=link_href)
                child_header_text = get_section_header_text(child)
                link.text = child_header_text or 'Unnamed Section'
                # Add link to doc
                p = html.Element('p')
                p.append(link)
                section_copy.append(p)
                # Process the child section recursively
                process_section(child, output_path)
            else:
                # Non-section content remains in the current section
                pass

        # Write the section to the output file
        output_file = os.path.join(output_path, f"{current_filename_base}.html")
        tree = etree.ElementTree(section_copy)
        tree.write(output_file, encoding='utf-8', method='html', pretty_print=True)
        return

    # Write the section to the output file
    output_file = os.path.join(output_dir, f"{current_filename_base}.html")
    tree = etree.ElementTree(section_element)
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

    # Process the root section
    process_section(section_element, output_dir)

if __name__ == '__main__':
    main()
