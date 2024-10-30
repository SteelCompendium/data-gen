import yaml
import sys
import argparse

def main():
    # Set up command-line argument parsing
    parser = argparse.ArgumentParser(description='Convert YAML statblocks into Markdown.')
    parser.add_argument('input_file', nargs='?', type=argparse.FileType('r'),
                        default=sys.stdin, help='Input YAML file')
    parser.add_argument('output_file', nargs='?', type=argparse.FileType('w'),
                        default=sys.stdout, help='Output Markdown file')
    args = parser.parse_args()

    # Read the YAML content from the input file
    yaml_content = args.input_file.read()
    data = yaml.safe_load(yaml_content)

    # Helper function to write to the output file
    def output(s=''):
        args.output_file.write(s + '\n')

    # Convert the name to uppercase for the header
    name = data.get('name', '').upper()
    output(f"### {name}\n")

    # Prepare the first table with stats
    level = data.get('level', '')
    roles = data.get('roles', [])
    roles_str = ' '.join(roles)
    ev = data.get('ev', '')
    ancestry = data.get('ancestry', [])
    ancestry_str = ', '.join(ancestry)
    stamina = data.get('stamina', '')
    weaknesses = data.get('weaknesses', [])
    weaknesses_str = '; '.join(weaknesses)
    speed = data.get('speed', '')
    size = data.get('size', '')
    stability = data.get('stability', '')
    free_strike = data.get('free_strike', '')

    # Build the table rows
    rows = []
    rows.append((name, f"**Level {level} {roles_str}**"))
    rows.append((f"*{ancestry_str}*", f"**EV {ev}**"))
    rows.append((f"**Stamina**: {stamina}", f"**Weakness**: {weaknesses_str}"))
    rows.append((f"**Speed**: {speed}", f"**Size**: {size} / Stability {stability}"))
    rows.append(('', f"**Free Strike**: {free_strike}"))

    # Print the table
    output(f"| {rows[0][0]} | {rows[0][1]} |")
    output(f"| :--------------- | -------------------------: |")
    for left_cell, right_cell in rows[1:]:
        output(f"| {left_cell} | {right_cell} |")

    # Prepare the characteristics table
    chars = ['might', 'agility', 'reason', 'intuition', 'presence']
    header_cells = []
    for char in chars:
        value = data.get(char, '')
        value = f"+{value}" if value and int(value) > 0 else value
        header_cells.append(f"**{char.capitalize()}** {value}")

    header_row = '| ' + ' | '.join(header_cells) + ' |'
    separator_row = '| ' + ' | '.join(['------------'] * len(chars)) + ' |'
    empty_row = '| ' + ' | '.join([''] * len(chars)) + ' |'

    # Print the characteristics table
    output()
    output(header_row)
    output(separator_row)
    output(empty_row)

    # Process abilities
    for ability in data.get('abilities', []):
        name = ability.get('name', '')
        cost = ability.get('cost', '')
        type = ability.get('type', '')
        if cost:
            name_line = f"#### {name} ({cost})"
        else:
            name_line = f"#### {name}"

        output()
        output(name_line)

        # Build the ability's table
        keywords = ability.get('keywords', [])
        keywords_str = ', '.join(keywords)
        distance = ability.get('distance', '')
        target = ability.get('target', '')

        table_rows = []
        if keywords_str or type:
            table_rows.append((f"Keywords: {keywords_str}", f"Type: {type}"))
        if distance or target:
            table_rows.append((f"Distance: {distance}", f"Target: {target}"))

        if table_rows:
            output()
            output(f"|     |     |")
            output(f"| :-- | :-- |")
            for left_cell, right_cell in table_rows:
                output(f"| {left_cell} | {right_cell} |")

        # Print the trigger if available
        trigger = ability.get('trigger', '')
        if trigger:
            output()
            output(f"Trigger: {trigger}")

        # Print the effects
        effects = ability.get('effects', [])
        for effect in effects:
            if "name" in effect:
                effect_name = effect.get('name', '')
                effect_text = effect.get('effect', '')
                output()
                output(f"**{effect_name}:** {effect_text}")
            elif "roll" in effect:
                output()
                output(f"**{effect.get('roll', '')}**")
                t1 = effect.get('t1', '')
                t2 = effect.get('t2', '')
                t3 = effect.get('t3', '')
                if t1:
                    output(f"- ✦ ≤11: {t1}")
                if t2:
                    output(f"- ★ 12-16: {t2}")
                if t3:
                    output(f"- ✸ 17+: {t3}")

    # Process traits
    output()
    for trait in data.get('traits', []):
        name = trait.get('name', '')
        effect = trait.get('effect', '')
        output(f"**{name}**\n")
        output(f"{effect}\n")

if __name__ == "__main__":
    main()
