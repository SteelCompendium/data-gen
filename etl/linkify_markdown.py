import re
import sys
import os

# Configuration
MAPPING_FILE = 'input/name_to_scc.yaml'
LINK_PREFIX = 'scc:'

def load_mapping(filepath):
    """
    Parses the simple YAML format "Key": "Value" generated previously.
    Returns a dictionary of name -> identifier.
    """
    mapping = {}
    print(f"Loading mapping from {filepath}...")
    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            for line in f:
                line = line.strip()
                # Skip comments and empty lines
                if not line or line.startswith('#') or line.startswith('---'):
                    continue
                
                # Parse "Key": "Value"
                # This regex looks for a quoted key, colon, and quoted value
                match = re.match(r'^"([^"]+)":\s*"([^"]+)"$', line)
                if match:
                    name, identifier = match.groups()
                    # Store lowercase key for case-insensitive matching, 
                    # but we could store original if we wanted strict matching.
                    # Given the request implies replacing "Watch Officer" (Title Case), 
                    # but text might vary, we'll index by lowercase.
                    if name.lower() not in mapping:
                        mapping[name.lower()] = identifier
    except FileNotFoundError:
        print(f"Error: Mapping file '{filepath}' not found.")
        sys.exit(1)
    
    print(f"Loaded {len(mapping)} mapping entries.")
    return mapping

def linkify_text(text, mapping):
    """
    Replaces occurrences of terms in 'mapping' with markdown links.
    Avoids replacing text inside existing links or code blocks.
    """
    
    # 1. Prepare keys sorted by length (descending) to avoid partial matching issues
    # (e.g. replacing "Elf" inside "High Elf")
    sorted_keys = sorted(mapping.keys(), key=len, reverse=True)
    
    if not sorted_keys:
        return text

    # 2. Compile regex for matching terms (whole words only)
    # We use re.escape to handle special chars in names
    # (?i) flag for case insensitivity is handled by passing re.IGNORECASE to split/sub? 
    # No, we'll build a big pattern.
    pattern_str = r'\b(' + '|'.join(map(re.escape, sorted_keys)) + r')\b'
    try:
        # High limit for regex groups might be hit if list is huge, 
        # but Python usually handles thousands fine in this construct.
        term_regex = re.compile(pattern_str, re.IGNORECASE)
    except re.error as e:
        print(f"Error compiling regex: {e}")
        return text

    # 3. Split content to isolate safe-to-replace text
    # Pattern captures:
    # Group 1: Code blocks ```...```
    # Group 2: Inline code `...`
    # Group 3: Existing markdown links [text](url)
    # The regex allows finding these "protected" chunks.
    
    protected_pattern = re.compile(
        r'(```[\s\S]*?```|`[^`]*`|\[.*?\]\(.*?\))'
    )
    
    parts = protected_pattern.split(text)
    
    processed_parts = []
    replacement_count = 0
    
    for part in parts:
        # If the part matches one of the protected patterns, keep it as is
        if protected_pattern.match(part):
            processed_parts.append(part)
        else:
            # It's plain text, apply replacements
            def replace_match(match):
                nonlocal replacement_count
                original_text = match.group(0)
                key = original_text.lower()
                if key in mapping:
                    replacement_count += 1
                    identifier = mapping[key]
                    return f"[{original_text}]({LINK_PREFIX}{identifier})"
                return original_text

            new_part = term_regex.sub(replace_match, part)
            processed_parts.append(new_part)
            
    print(f"Performed {replacement_count} replacements.")
    return "".join(processed_parts)

def main():
    if len(sys.argv) < 2:
        print("Usage: python linkify_markdown.py <file_path>")
        sys.exit(1)
        
    target_file = sys.argv[1]
    
    if not os.path.exists(target_file):
        print(f"Error: Target file '{target_file}' not found.")
        sys.exit(1)
        
    mapping = load_mapping(MAPPING_FILE)
    
    print(f"Reading {target_file}...")
    with open(target_file, 'r', encoding='utf-8') as f:
        content = f.read()
        
    new_content = linkify_text(content, mapping)
    
    if content != new_content:
        print(f"Writing changes to {target_file}...")
        with open(target_file, 'w', encoding='utf-8') as f:
            f.write(new_content)
        print("Done.")
    else:
        print("No changes made.")

if __name__ == "__main__":
    main()