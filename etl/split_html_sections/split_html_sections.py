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
    #value = re.sub(r'[^\w\s-]', '', value).strip().lower()
    # Replace whitespace and hyphens with a single hyphen
    #value = re.sub(r'[-\s]+', '-', value)

    # Replace whitespace single space
    value = re.sub(r'[\s]+', ' ', value)
    return value.title()

def title_case_filename(filename):
    # Split the filename and extension
    name, ext = os.path.splitext(filename)
    # Split the name into words, including non-alphanumeric characters
    words = re.split(r'(\W+)', name)
    capitalized_words = []
    for word in words:
        if word.isalpha():
            capitalized_words.append(word.capitalize())
        elif word.isdigit():
            capitalized_words.append(word)
        else:
            capitalized_words.append(word)
    new_name = ''.join(capitalized_words)
    # Return the new filename with the extension in lowercase
    return new_name + ext.lower()

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
            if not (current_id and child_id == current_id + '-1'):
                has_separate_child_sections = True
                break
    return has_separate_child_sections

def process_section(section_element, parent_id, output_dir):
    # Get the current section's id and name
    current_id = section_element.get('id', '')
    section_name = get_section_name(section_element)

    # Determine whether to embed or output separately
    if parent_id and current_id == parent_id + '-1':
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

    # Create the output file
    if has_separate_child_sections:
        output_file = os.path.join(output_path, 'index.html')
    else:
        output_file = os.path.join(output_path, f"{section_name}.html")

    # Make a copy of the section element for output
    section_copy = copy.deepcopy(section_element)

    # Process child elements
    for child in list(section_copy):
        if child.tag == 'section':
            child_id = child.get('id', '')
            child_name = get_section_name(child)
            if current_id and child_id == current_id + '-1':
                # Embed the child section
                process_section(child, current_id, output_path)
            else:
                # Remove the child section from the current section
                section_copy.remove(child)
                # Determine whether the child will be output as a directory
                child_is_directory = will_output_as_directory(child, child_id)
                # Insert a link to the child section
                if child_is_directory:
                    link_href = f'./{child_name}/index.html'
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
