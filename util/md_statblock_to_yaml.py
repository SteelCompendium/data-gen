import re
import yaml

def parse_header(markdown_text):
    """
    Extracts the name of the statblock from the header.
    """
    lines = markdown_text.strip().split('\n')
    for line in lines:
        line = line.strip()
        if re.match(r'^#{2,6}', line):
            name = line.lstrip('#').strip()
            return name.title()
    return None

def parse_markdown_statblock(markdown_text):
    data = {}
    lines = markdown_text.strip().split('\n')

    # Process the header
    name = parse_header(markdown_text)
    if name:
        data['name'] = name

    # Initialize variables (forcing everything for ordering)
    data['ancestry'] = []
    data['roles'] = []
    data['level'] = ''
    data['ev'] = ''
    data['stamina'] = ''
    data['immunities'] = []
    data['weaknesses'] = []
    data['speed'] = ''
    data['size'] = ''
    data['stability'] = ''
    data['free_strike'] = ''
    data['might'] = ''
    data['intuition'] = ''
    data['agility'] = ''
    data['reason'] = ''
    data['presence'] = ''
    data['traits'] = []
    data['abilities'] = []

    i = 0

    while i < len(lines):
        line = lines[i].strip()
        if not line:
            i += 1
            continue

        # Level and Role
        match = re.match(r'\*\*Level\s+(\d+)\s+(.+)\*\*', line)
        if match:
            data['level'] = int(match.group(1))
            roles = match.group(2).split()
            data['roles'] = [role.strip() for role in roles]
            i += 1
            continue

        # Ancestry line '*Ancestry*' (ensure line starts and ends with a single asterisk)
        if line.startswith('*') and line.endswith('*') and line.count('*') == 2:
            ancestry = line.strip('*').split(',')
            data['ancestry'] = [a.strip() for a in ancestry]
            i += 1
            continue

        # EV line '**EV XX**'
        match = re.match(r'\*\*EV\s*(\d+)\*\*', line)
        if match:
            data['ev'] = int(match.group(1))
            i +=1
            continue

        # Basic stat line '**Key**: Value'
        match = re.match(r'\*\*(.+?)\*\*:\s*(.+)', line)
        if match:
            key = match.group(1).strip().lower().replace(' ', '_')
            value = match.group(2).strip()
            if key in ['stamina', 'free_strike']:
                data[key] = int(value)
            elif key == 'speed':
                data[key] = value
            elif key == 'size':
                if '/' in value:
                    size_part, stability_part = value.split('/')
                    data['size'] = size_part.strip()
                    stability_match = re.search(r'Stability\s*([+-−]?\d+)', stability_part)
                    if stability_match:
                        data['stability'] = int(stability_match.group(1).replace('−', '-'))
                else:
                    data['size'] = value
            else:
                data[key] = value
            i +=1
            continue

        # Characteristic line '- **Characteristic** +/-N'
        match = re.match(r'-\s*\*\*(.+?)\*\*\s*([+-−]?\d+)', line)
        if match:
            key = match.group(1).strip().lower()
            value = match.group(2).replace('−', '-')
            data[key] = int(value)
            i +=1
            continue

        # Ability line: Lines that contain '◆' are abilities
        if line.startswith('**') and '◆' in line:
            ability, new_i = parse_ability(lines, i)
            data['abilities'].append(ability)
            i = new_i
            continue

        # Trait line: Lines that start and end with '**' but do not contain '◆'
        if line.startswith('**') and line.endswith('**') and '◆' not in line:
            trait, new_i = parse_trait(lines, i)
            data['traits'].append(trait)
            i = new_i
            continue

        # Unknown line, skip
        i +=1

    return data

def parse_ability(lines, index):
    ability = {}
    i = index

    first_line = lines[i].strip()

    # Pattern: '**Name (Type)** ◆ Roll ◆ Cost'
    match = re.match(r'\*\*(.+?)\s*(?:\((.+?)\))?\*\*\s*◆\s*(.+?)\s*◆\s*(.+)', first_line)
    if match:
        ability['name'] = match.group(1).strip()
        if match.group(2):
            ability['type'] = match.group(2).strip()
        ability['roll'] = match.group(3).strip()
        ability['cost'] = match.group(4).strip()
    else:
        # Pattern: '**Name (Type)** ◆ Roll'
        match = re.match(r'\*\*(.+?)\s*(?:\((.+?)\))?\*\*\s*◆\s*(.+)', first_line)
        if match:
            ability['name'] = match.group(1).strip()
            if match.group(2):
                ability['type'] = match.group(2).strip()
            ability['roll'] = match.group(3).strip()
        else:
            # Pattern: '**Name (Type)**'
            match = re.match(r'\*\*(.+?)\s*\((.+?)\)\*\*', first_line)
            if match:
                ability['name'] = match.group(1).strip()
                ability['type'] = match.group(2).strip()
            else:
                # Pattern: '**Name**'
                match = re.match(r'\*\*(.+?)\*\*', first_line)
                if match:
                    ability['name'] = match.group(1).strip()

    i += 1

    # Now process the rest of the lines
    while i < len(lines):
        line = lines[i].strip()
        if not line:
            i +=1
            continue

        if line.startswith('**') and ('◆' in line or '◆' not in line):
            # Start of next ability or trait
            break
        if line.startswith('- **'):
            # Start of characteristics
            break

        # Keywords
        if line.startswith('Keywords:'):
            keywords_line = line[len('Keywords:'):].strip()
            ability['keywords'] = [k.strip() for k in keywords_line.split(',')]
            i += 1
            continue

        # Distance
        if line.startswith('Distance:'):
            ability['distance'] = line[len('Distance:'):].strip()
            i += 1
            continue

        # Target
        if line.startswith('Target:'):
            ability['target'] = line[len('Target:'):].strip()
            i += 1
            continue

        # Trigger
        if line.startswith('Trigger:'):
            ability['trigger'] = line[len('Trigger:'):].strip()
            i += 1
            continue

        # Effect
        if line.startswith('Effect:'):
            effect_lines = [line[len('Effect:'):].strip()]
            i += 1
            while i < len(lines) and not lines[i].strip().startswith('-') and not lines[i].strip().startswith('**') and not lines[i].strip().startswith('Special:'):
                effect_lines.append(lines[i].strip())
                i += 1
            ability['effect'] = ' '.join(effect_lines)
            continue

        # Special
        if line.startswith('Special:'):
            special_lines = [line[len('Special:'):].strip()]
            i += 1
            while i < len(lines) and not lines[i].strip().startswith('-') and not lines[i].strip().startswith('**') and not lines[i].strip().startswith('Effect:'):
                special_lines.append(lines[i].strip())
                i += 1
            ability['special'] = ' '.join(special_lines)
            continue

        # Tiers
        if line.startswith('-'):
            while i < len(lines) and lines[i].strip().startswith('-'):
                tier_line = lines[i].strip()
                tier_match = re.match(r'-\s*([✦★✸])?\s*(.+?):\s*(.+)', tier_line)
                if tier_match:
                    symbol = tier_match.group(1)
                    threshold = tier_match.group(2).strip()
                    description = tier_match.group(3).strip()
                    # Collect continuation lines
                    i += 1
                    while i < len(lines) and not lines[i].strip().startswith('-') and not lines[i].strip().startswith('**') and not lines[i].strip().startswith('Effect:') and not lines[i].strip().startswith('Special:'):
                        description += ' ' + lines[i].strip()
                        i += 1
                    # Map symbol to tier
                    if symbol == '✦':
                        ability['t1'] = description
                    elif symbol == '★':
                        ability['t2'] = description
                    elif symbol == '✸':
                        ability['t3'] = description
                    else:
                        if 'tiers' not in ability:
                            ability['tiers'] = []
                        ability['tiers'].append({'threshold': threshold, 'description': description})
                else:
                    i += 1
            continue

        # Unknown line, increment
        i += 1

    return ability, i

def parse_trait(lines, index):
    trait = {}
    i = index
    trait_lines = []
    trait_name_line = lines[i].strip()
    trait['name'] = trait_name_line.strip('*').strip()
    i += 1
    while i < len(lines):
        line = lines[i].strip()
        if line.startswith('**') and ('◆' in line or '◆' not in line):
            break
        elif line.startswith('- **'):
            break
        else:
            trait_lines.append(line)
            i += 1
    trait['effect'] = ' '.join(trait_lines).strip()
    return trait, i

def process_markdown(markdown_text):
    """
    Processes the markdown statblock and returns a YAML string.

    Args:
        markdown_text (str): The markdown text of the statblock.

    Returns:
        str: The YAML representation of the statblock.
    """
    data = parse_markdown_statblock(markdown_text)
    yaml_string = yaml.dump(data, sort_keys=False, allow_unicode=True)
    return yaml_string
