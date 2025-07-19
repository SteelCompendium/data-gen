# This recipe will attempt to "correct" the headers in a markdown document if you have a "truth" toc doc.
# No idea if this is useful depending on whether its worth building the truth doc.
# Usage: just run path/to/your-doc.md path/to/headers.md path/to/output.md
run input_md_path headers_path output_md_path:
    #!/usr/bin/env python3

    import re, difflib, sys, unicodedata

    # 1) Parse headers.md into ordered list (up to 8 levels), strip any cost in truth entries
    pattern_hdr = re.compile(r'^(#{1,8})\s*(.+?)\s*$')
    cost_suffix = re.compile(r'(\s*\(.*\))$')
    hdr_list = []
    with open('{{headers_path}}', encoding='utf-8') as hf:
        for line in hf:
            m = pattern_hdr.match(line)
            if m:
                text = m.group(2).strip()
                # remove cost if present in headers.md
                cost_m = cost_suffix.search(text)
                base = cost_suffix.sub('', text).strip()
                lvl = len(m.group(1))
                hdr_list.append({'base': base, 'level': lvl})

    ordered_bases = [h['base'] for h in hdr_list]
    hdr_map = {h['base']: h['level'] for h in hdr_list}

    # 2) Normalization helper for fuzzy matching
    def normalize_text(s):
        s = unicodedata.normalize('NFKD', s)
        s = ''.join(ch for ch in s if not unicodedata.combining(ch))
        s = s.lower()
        s = re.sub(r'[^\w\s]', '', s)
        s = re.sub(r'\s+', ' ', s).strip()
        return s

    norm_to_truth = {normalize_text(base): base for base in ordered_bases}
    normalized_bases = list(norm_to_truth.keys())

    # 3) Regexes to detect headers in input.md
    header_line = re.compile(r'^[ \t]*(#{1,8})\s*(.+?)\s*$')
    bold_strip  = re.compile(r'^\*\*(.+?)\*\*$')

    current_pos = 0
    matched = set()

    def normalize_line(line):
        global current_pos
        m = header_line.match(line)
        if not m:
            return line  # leave non-header lines untouched

        core = m.group(2).strip()
        # unwrap **bold**
        b = bold_strip.match(core)
        if b:
            core = b.group(1).strip()

        # pull off cost "(…)"
        cost_m = cost_suffix.search(core)
        cost_in = cost_m.group(1) if cost_m else ''
        base_in = cost_suffix.sub('', core).strip()

        base_norm = normalize_text(base_in)
        slice_norm = normalized_bases[current_pos:]
        match = difflib.get_close_matches(base_norm, slice_norm, n=1, cutoff=0.8)
        if not match:
            match = difflib.get_close_matches(base_norm, normalized_bases, n=1, cutoff=0.8)

        if match:
            truth_base = norm_to_truth[match[0]]
            # verify word count on base only
            if len(truth_base.split()) != len(base_in.split()):
                print(f"[DEMOTE] Word count mismatch: “{base_in}” vs truth “{truth_base}”", file=sys.stderr)
                return f'{core}\n'
            lvl = hdr_map[truth_base]
            matched.add(truth_base)
            idx = ordered_bases.index(truth_base)
            if idx >= current_pos:
                current_pos = idx + 1
            # reconstruct header with input cost
            return f'{"#"*lvl} {truth_base}{cost_in}\n'
        else:
            print(f"[DEMOTE] Not found in truth list: “{base_in}”", file=sys.stderr)
            return f'{core}\n'

    # 4) Process input and write output
    with open('{{input_md_path}}', encoding='utf-8') as inp, open('{{output_md_path}}', 'w', encoding='utf-8') as out:
        for line in inp:
            out.write(normalize_line(line))

    # 5) Report any truth headers never matched
    missing = [b for b in ordered_bases if b not in matched]
    if missing:
        print("\nMissing headers:", file=sys.stderr)
        for b in missing:
            print(f"- {b}", file=sys.stderr)
        print(f"Total missing: {len(missing)}", file=sys.stderr)
    else:
        print("All headers matched.", file=sys.stderr)