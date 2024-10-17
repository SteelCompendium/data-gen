import re
import sys

# Formatting and cleanup on statblocks
# Converts ktdt tables, characteristic tables, cleans up newlines, etc
########################################################################################################################

def process_block(block_lines):
    # Extract the name from the '#### ' line
    name_line = block_lines[0]
    name = name_line.strip('# ').strip()

    items = []
    abilities = []
    other_content = []
    state = 'items'  # Possible states: 'items', 'abilities', 'other_content'

    for line in block_lines[1:]:
        line = line.strip()

        if not line:
            continue  # Skip empty lines

        if state == 'items':
            if line.startswith('- **Might**'):
                abilities.append(line)
                state = 'abilities'
            else:
                items.append(line)
        elif state == 'abilities':
            abilities.append(line)
            if len(abilities) == 5:
                state = 'other_content'  # Assuming there are always 5 abilities
        else:
            other_content.append(line)

    # Process items
    level = items[0] if items else ''
    type_line = items[1] if len(items) > 1 else ''
    ev = items[2] if len(items) > 2 else ''

    # Collect the rest of the items and pair them
    rest_items = items[3:]
    item_pairs = []

    n = len(rest_items)
    for i in range(0, n - 1, 2):
        left = rest_items[i]
        right = rest_items[i + 1]
        item_pairs.append((left, right))

    if n % 2 == 1:
        # If there's an odd number of rest_items, last item goes on the right with empty left
        item_pairs.append(('', rest_items[-1]))

    # Build the markdown table
    table_lines = []
    table_lines.append(f'| {name} | {level.strip()} |')
    table_lines.append('|:-------------------------------------------------- | -------------------------:|')
    table_lines.append(f'| {type_line} | {ev} |')

    for left, right in item_pairs:
        table_lines.append(f'| {left} | {right} |')

    # Process abilities
    if abilities:
        ability_headers = [ability.lstrip('- ').strip() for ability in abilities]
        separator = ['-' * (len(header) - 4) for header in ability_headers]  # Adjust for '**'
        empty_row = ['' for _ in ability_headers]

        ability_table = [
            '| ' + ' | '.join(ability_headers) + ' |',
            '| ' + ' | '.join(separator) + ' |',
            '| ' + ' | '.join(empty_row) + ' |',
            ]
    else:
        ability_table = []

    # Process other content (abilities, maneuvers, etc.)
    processed_other_content = process_other_content(other_content)

    # Combine all lines, including other content
    result_lines = [f'#### {name}', ''] + table_lines + [''] + ability_table + [''] + processed_other_content + ['']

    return result_lines

def process_other_content(other_content):
    result = []
    i = 0
    while i < len(other_content):
        line = other_content[i]

        # Check if line is an ability start (e.g., starts and ends with '**')
        ability_start_match = re.match(r'\*\*.*\*\*.*', line)
        if ability_start_match:
            # Insert empty line before ability, unless it's the first line
            if result and result[-1] != '':
                result.append('')

            # Add the ability name line
            result.append(line)

            # Insert empty line after ability name line
            result.append('')

            i += 1
        else:
            # If line starts with 'Effect:' or 'Effect', add empty line before
            if line.strip().startswith('Effect:') or line.strip().startswith('Effect'):
                if result and result[-1] != '':
                    result.append('')
                result.append(line)
            else:
                result.append(line)
            i += 1

    # Remove any extra empty lines at the end
    while result and result[-1] == '':
        result.pop()

    return result

def main():
    if len(sys.argv) != 2:
        print("Usage: python format_statblock.py <input_markdown_file>")
        sys.exit(1)

    input_filename = sys.argv[1]

    with open(input_filename, 'r', encoding='utf-8') as f:
        lines = f.readlines()

    output_lines = []
    block_lines = []
    in_block = False

    for line in lines:
        if line.strip().startswith('#### '):
            # Process the previous block if it exists
            if block_lines:
                processed_block = process_block(block_lines)
                output_lines.extend(processed_block)
                block_lines = []
            in_block = True
            block_lines.append(line.rstrip('\n'))
        elif in_block:
            # Continue collecting lines for the current block
            block_lines.append(line.rstrip('\n'))
        else:
            # Outside of any block, just add the line to output
            output_lines.append(line.rstrip('\n'))

    # Process the last block if it exists
    if block_lines:
        processed_block = process_block(block_lines)
        output_lines.extend(processed_block)

    # Write the output to a file
    with open(input_filename, 'w', encoding='utf-8') as f:
        for line in output_lines:
            f.write(line + '\n')

if __name__ == '__main__':
    main()
