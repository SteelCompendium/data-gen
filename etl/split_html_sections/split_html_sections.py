import os
import sys
import shutil
import copy
import re
import unicodedata
from lxml import html, etree

def slugify(value):
    """
    Converts a string to a filesystem-safe slug.
    """
    value = str(value)
    # Normalize unicode characters
    value = unicodedata.normalize('NFKD', value).encode('ascii', 'ignore').decode('ascii')
    # Remove invalid characters
    value = re.sub(r'[^\w\s\-()]', '', value)
    # Replace whitespace single space
    value = re.sub(r'[\s]+', ' ', value)
    # Some abilities have costs in the name, remove the cost
    value = re.sub(r'\s+\(.+\)', '', value)
    # Title case
    value = title_case(value)
    return value

def title_case(s):
    # Split the string by whitespace and hyphens
    words = re.split(r'(\s+|-)', s)

    # Capitalize each word and join back, keeping separators
    return ''.join([word.capitalize() if word.isalnum() else word for word in words])

def should_embed(current_id, parent_id):
    return parent_id and (current_id == parent_id + '-1' or current_id.startswith(parent_id))

def get_section_name(section_element):
    """
    Extracts and sanitizes the first header's text from a section element.
    """
    header = section_element.xpath('.//h1|.//h2|.//h3|.//h4|.//h5|.//h6')
    if header:
        header_text = header[0].text_content()
        return slugify(header_text)
    else:
        # Fallback to 'section' if no header is found
        return 'section'

def will_output_as_directory(section_element, current_id):
    """
    Determines whether a section will be output as a directory based on its child sections.
    """
    has_separate_child_sections = False
    for child in section_element:
        if child.tag == 'section':
            child_id = child.get('id', '')
            if not should_embed(child_id, current_id):
                has_separate_child_sections = True
                break
    return has_separate_child_sections

def process_section(section_element, parent_id, output_dir):
    # Get the current section's id and name
    current_id = section_element.get('id', '')
    section_name = get_section_name(section_element)

    # Determine whether to embed or output separately
    if should_embed(current_id, parent_id):
        # Embed the section
        for child in section_element:
            if child.tag == 'section':
                process_section(child, current_id, output_dir)
        return

    # Decide whether to create a directory or just an HTML file
    has_separate_child_sections = will_output_as_directory(section_element, current_id)
    if has_separate_child_sections:
        # Output as separate directory
        section_dir = os.path.join(output_dir, section_name)
        os.makedirs(section_dir, exist_ok=True)
        output_path = section_dir
    else:
        # Output as a single file in the output_dir
        output_path = output_dir

    output_file = os.path.join(output_path, f"{section_name}.html")

    # Make a copy of the section element for output
    section_copy = copy.deepcopy(section_element)

    # Process child elements
    for child in list(section_copy):
        if child.tag == 'section':
            child_id = child.get('id', '')
            child_name = get_section_name(child)
            if should_embed(child_id, current_id):
                # Embed the child section
                process_section(child, current_id, output_path)
            else:
                # Remove the child section from the current section
                section_copy.remove(child)
                # Determine whether the child will be output as a directory
                child_is_directory = will_output_as_directory(child, child_id)
                # Insert a link to the child section
                if child_is_directory:
                    link_href = f'./{child_name}/{child_name}.html'
                else:
                    link_href = f'./{child_name}.html'
                link = html.Element('a', href=link_href)
                # Use the child header's text as the link text
                header = child.xpath('.//h1|.//h2|.//h3|.//h4|.//h5|.//h6')
                if header:
                    link.text = header[0].text_content()
                else:
                    link.text = child_name

                # Append the link to the section
                p = html.Element('p')
                p.append(link)
                section_copy.append(p)
                # Process the child section recursively
                process_section(child, current_id, output_path)
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
    # if os.path.exists(output_dir):
    #     shutil.rmtree(output_dir)

    # Create the output directory
    os.makedirs(output_dir, exist_ok=True)

    # Process the root section
    process_section(section_element, parent_id=None, output_dir=output_dir)

if __name__ == '__main__':
    main()
