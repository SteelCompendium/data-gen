# TODO - im 99% sure this is not needed.  toc.just will build the toc file, then abilities.just will handle the rest

# Usage: just run path/to/your/headers_toc.md
# ~/code/personal/steelCompendium $ just -f data-gen/etl/pre-automation-tools/toc_to_ability_hierarchy.justfile run data-gen/temp/toc.md
#
# Prints out all the "leaf" items in the toc with their "path" (hierarchy)

[no-cd]
run file_path:
    #!/usr/bin/env python3
    import sys
    import re

    def parse_headings(filepath):
        """
        Parses a markdown file and extracts all headings.
        Returns a list of tuples, where each tuple is (level, title).
        """
        headings = []
        try:
            with open(filepath, 'r') as f:
                for line in f:
                    match = re.match(r'^(#+)\s+(.*)', line)
                    if match:
                        level = len(match.group(1))
                        title = match.group(2).strip()
                        headings.append((level, title))
        except FileNotFoundError:
            print(f"Error: File not found at {filepath}", file=sys.stderr)
            sys.exit(1)
        return headings

    def main():
        filepath = '{{file_path}}'
        headings = parse_headings(filepath)

        if not headings:
            return

        for i in range(len(headings)):
            is_leaf = False
            if i == len(headings) - 1:
                is_leaf = True
            else:
                current_level, _ = headings[i]
                next_level, _ = headings[i+1]
                if next_level <= current_level:
                    is_leaf = True

            if is_leaf:
                current_level, current_title = headings[i]
                path = [current_title]
                
                parent_level = current_level
                for j in range(i - 1, -1, -1):
                    prev_level, prev_title = headings[j]
                    if prev_level < parent_level:
                        path.insert(0, prev_title)
                        parent_level = prev_level
                
                print(f"{'/'.join(path)}")

    if __name__ == "__main__":
        main()