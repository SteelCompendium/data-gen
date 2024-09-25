#!/usr/bin/env python3

import os
import argparse
import yaml
import frontmatter
from tabulate import tabulate

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
    # Filter abilities that have all the required columns
    filtered_abilities = []
    for ability in abilities:
        if all(column in ability for column in columns):
            filtered_abilities.append(ability)
        else:
            # You can choose to handle missing columns differently
            # For now, we include abilities even if some columns are missing
            filtered_abilities.append(ability)

    # Build table data
    table_data = []
    for ability in filtered_abilities:
        row = [ability.get(column, '') for column in columns]
        if row[0] != "":
            table_data.append(row)

    # Generate markdown table using tabulate
    table = tabulate(table_data, headers=columns, tablefmt='github')
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
