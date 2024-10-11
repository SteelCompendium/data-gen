#!/usr/bin/env python3

import os
import argparse
import frontmatter
from tabulate import tabulate

# This file is used to build a markdown table containing all the abilities included in a dir
# Used for building a table of class abilities

def collect_abilities(root_dir):
    abilities = []
    for dirpath, dirnames, filenames in os.walk(root_dir):
        for filename in filenames:
            if filename.endswith('.md'):
                file_path = os.path.join(dirpath, filename)
                with open(file_path, 'r', encoding='utf-8') as f:
                    post = frontmatter.load(f)
                    ability = post.metadata
                    ability['file_path'] = file_path  # Optional: Include file path
                    abilities.append(ability)
    return abilities

def build_table(abilities, columns):
    # Build table data
    table_data = []
    for ability in abilities:
        row = [ability.get(column, '') for column in columns]
        if row[0] != "":
            table_data.append(row)

    header_values = [header.title().replace("_", " ") for header in columns]
    # Generate markdown table using tabulate
    table = tabulate(table_data, headers=header_values, tablefmt='github')
    return table

def main():
    parser = argparse.ArgumentParser(description='Build a markdown table of abilities.')
    parser.add_argument('root_dir', help='Root directory containing ability types.')
    parser.add_argument('-c', '--columns', nargs='+', required=True, help='Columns to include in the table.')
    parser.add_argument('-o', '--output', help='Output markdown file. If not specified, prints to stdout.')
    args = parser.parse_args()

    abilities = collect_abilities(args.root_dir)
    table = build_table(abilities, args.columns)

    if args.output:
        with open(args.output, 'w', encoding='utf-8') as f:
            f.write(table)
        print(f'Table written to {args.output}')
    else:
        print(table)

if __name__ == '__main__':
    main()
