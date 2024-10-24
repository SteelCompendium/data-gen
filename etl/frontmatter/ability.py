#!/usr/bin/env python3

import argparse
import sys
import re
import json
import yaml

def title_case(s):
    # Split the string by whitespace and hyphens
    words = re.split(r'(\s+|-)', s)

    # Capitalize each word and join back, keeping separators
    return ''.join([word.capitalize() if word.isalnum() else word for word in words])

def extract_information(md_content, args):
    frontmatter = {}

    # extract title from H1 header
    title_match = re.search(r'^#\s+(.*)', md_content, re.MULTILINE)
    if title_match:
        title = title_match.group(1).strip()
        frontmatter['title_raw'] = title
        frontmatter['title'] = title_case(title)
    else:
        print('Error: No H1 header found in the markdown content to extract the title.')
        sys.exit(1)

    # Extract the name (text before '(' in the title)
    name_match = re.match(r'([^\(]+)', frontmatter['title_raw'])
    if name_match:
        name = name_match.group(1).strip()
        frontmatter['name_raw'] = name
        frontmatter['name'] = title_case(name)
    else:
        frontmatter['name_raw'] = frontmatter['title_raw']
        frontmatter['name'] = title_case(frontmatter['title_raw'])

    # Extract the cost (text inside parentheses in the title)
    cost_match = re.match(r'.*\(([^\)]+)\)', frontmatter['title'])
    if cost_match:
        cost = cost_match.group(1).strip()
        frontmatter['cost'] = cost

    # Use provided type and subtype
    if args.type:
        frontmatter['type'] = args.type.strip()

    if args.subtype:
        frontmatter['subtype'] = args.subtype.strip()

    if args.kind:
        frontmatter['kind'] = args.kind.strip()

    # Extract ability key-value pairs
    ability_kv_pairs = re.findall(
        r'^\-?\s*\*\*([^:\*]+?)\**:\**\s*(\S.*?)\s*$',
        md_content,
        re.MULTILINE | re.DOTALL
    )
    ability_dict = dict()

    for key, value in ability_kv_pairs:
        key = key.strip()
        value = value.strip() if value else ''
        ability_dict[key] = value

    # Extract specific keys if they exist
    if 'Keywords' in ability_dict:
        keywords = ability_dict['Keywords']
        frontmatter['keywords'] = keywords
        # Create a list from comma-separated keywords
        frontmatter['keyword_list'] = [kw.strip() for kw in re.split(r',\s*', keywords)]

    if 'Type' in ability_dict:
        frontmatter['ability_type'] = ability_dict['Type']

    if 'Distance' in ability_dict:
        frontmatter['distance'] = ability_dict['Distance']

    if 'Target' in ability_dict:
        frontmatter['target'] = ability_dict['Target']

    if 'Trigger' in ability_dict:
        frontmatter['trigger'] = ability_dict['Trigger']

    return frontmatter

def main():
    parser = argparse.ArgumentParser(description='Parse a markdown file or string and extract frontmatter.')
    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument('-s', '--string', help='Markdown content as a string.')
    group.add_argument('-f', '--file', help='Path to the markdown file.')
    parser.add_argument('-t', '--type', help='Type value.')
    parser.add_argument('--subtype', help='Subtype value.')
    parser.add_argument('-k', '--kind', help='Kind value (triggered, signature, etc).')
    parser.add_argument('-o', '--output-format', choices=['json', 'yaml', 'frontmatter'], default='yaml', help='Output format (json, yaml, or frontmatter).')
    args = parser.parse_args()

    if args.string:
        md_content = args.string
    elif args.file:
        try:
            with open(args.file, 'r', encoding='utf-8') as f:
                md_content = f.read()
        except FileNotFoundError:
            print(f'Error: File "{args.file}" not found.')
            sys.exit(1)
    else:
        print('Error: Either --string or --file must be provided.')
        sys.exit(1)

    frontmatter = extract_information(md_content, args)

    if args.output_format == 'json':
        print(json.dumps(frontmatter, indent=2))
    elif args.output_format == 'frontmatter':
        print('---')
        print(yaml.dump(frontmatter, sort_keys=False).strip())
        print('---')
    else:
        print(yaml.dump(frontmatter, sort_keys=False).strip())

if __name__ == '__main__':
    main()
