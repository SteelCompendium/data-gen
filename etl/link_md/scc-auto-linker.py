#!/usr/bin/env python3
"""
SCC Auto-Linker: Injects scc: URI links into Draw Steel markdown files.

Operates in three tiers:
  Tier 1 (auto): Unambiguous multi-word terms. Applied automatically.
  Tier 2 (auto): Single-word game terms that are unambiguous in context.
  Tier 3 (review): Ambiguous terms. Outputs a report for manual review.

Usage:
  python scc-auto-linker.py <markdown_file> <scc_to_path.json> [--dry-run] [--report <report_file>] [--tier 1|2|3|all]
  python scc-auto-linker.py <markdown_file> <scc_to_path.json> --term <slug> [--dry-run]
  python scc-auto-linker.py <markdown_file> <scc_to_path.json> --clean [--dry-run]

The --term flag promotes a single tier-3 term to auto-link, ignoring AMBIGUOUS_TERMS
and TIER3_TYPES for that term only. Useful for reviewing one dangerous term at a time.
The slug is the kebab-case ID (e.g., "noble", "free-strike", "animal-form").
Combine with --dry-run to preview without writing.
"""

import argparse
import json
import re
import sys
from dataclasses import dataclass, field


# ---------------------------------------------------------------------------
# Tier classification
# ---------------------------------------------------------------------------

# Tier 3: Terms too ambiguous to auto-link (common English words that
# collide with game terms). Values are the scc type they collide with.
AMBIGUOUS_TERMS = {
    # Classes -- common English words
    "shadow", "null", "fury", "talent", "conduit",
    # Common abilities -- verbs used in prose
    "grab", "hide", "charge", "defend", "heal", "ride",
    # Movements -- common verbs
    "walk", "jump", "fly",
    # Complications -- common English words
    "ward", "exile", "runaway", "amnesia", "hunted", "coward",
    "pirate", "loner", "rival", "medium", "hunter", "lucky",
    "mundane", "outlaw", "refugee", "grifter", "grounded",
    # Careers -- generic words
    "agent", "sage", "soldier", "criminal", "laborer", "farmer",
    "performer", "artisan", "beggar", "sailor", "disciple",
    # Titles
    "knight", "noble",
    # Move/maneuver actions -- common verbs
    "advance", "disengage",
    # Movements -- common verbs or words
    "crawl", "hover",
    # Kits -- common words
    "raider", "ranger", "sniper", "mountain", "panther",
    # Perks -- common words used in prose
    "teamwork",
    # Others that I found to be unsafe
    "animal form", "whirlwind", "teleport", "human", "devil", "when a creature moves", "climb", "jump", "swim", "vertical",
    "elementalist",
    # Titles/features with generic English usage
    "doomed", "spotlight",
    "primordial power", "null field", "hit and run", "order", "skill", "divine power", "triggered action", "kit",
    "friend", "foil", "perk", "again", "blocking", "breath", "signature ability", "vision", "virtue", "warmaster",
    "judgement", "mark", "psion", "focus outside of combat", "focus", "one"
}

# Terms that should NEVER be linked (too generic or would create noise)
SKIP_TERMS = {
    "stand up",   # too common in prose
    "use consumable",  # too long/specific
    "make or assist a test",  # too long
    "search for hidden creatures",  # too long
}

# Types that should not be auto-linked (too generic, or cross-source noise)
SKIP_TYPES = {
    "chapter",      # "combat", "tests", "rewards" etc. are common words
    "keywords",     # "dragon", "animal", "plant" etc. are too generic
    "feature",      # class features are too numerous and context-dependent
    "monster",      # monster names don't belong in heroes prose
}

# Types where ALL terms are tier 3 (review only) regardless of word count
TIER3_TYPES = {
    "title",        # "doomed", "scarred", "teacher" etc. are common English
    "perk",         # "familiar", "handy", "teamwork" etc. are common English
    "career",       # most career names are common words
}

# Irregular plurals: display_singular -> [plural_forms]
IRREGULAR_PLURALS = {
    "fury": ["furies"],
    "dwarf": ["dwarves"],
    "ancestry": ["ancestries"],
    "polder": ["polders"],
    "hakaan": ["hakaan"],  # same plural
    "human": ["humans"],
    "orc": ["orcs"],
    "devil": ["devils"],
    "wode elf": ["wode elves"],
    "high elf": ["high elves"],
    "dragon knight": ["dragon knights"],
    "memonek": ["memoneks", "memonek"],
    "revenant": ["revenants"],
    "time raider": ["time raiders"],
    "class": ["classes"],
}


@dataclass
class LinkTerm:
    """A term that can be linked."""
    display: str          # Display form (e.g., "dragon knight")
    scc_key: str          # Full SCC key
    scc_type: str         # Type component (e.g., "class", "condition")
    tier: int             # 1, 2, or 3
    variants: list = field(default_factory=list)  # Plural/alternate forms


def classify_tier(display: str, scc_type: str, promote_terms: set[str] | None = None) -> int:
    """Classify a term into a linking tier.

    Args:
        promote_terms: If set, these term slugs bypass AMBIGUOUS_TERMS and
                       TIER3_TYPES, getting promoted to tier 2 (auto-link).
    """
    display_lower = display.lower()

    if display_lower in SKIP_TERMS:
        return 0  # skip entirely

    # --term promotion: override ambiguity for specific terms
    if promote_terms and display_lower in promote_terms:
        return 2

    # Entire types that are too ambiguous for auto-linking
    if scc_type in TIER3_TYPES:
        return 3

    # Multi-word terms are almost always unambiguous
    if " " in display_lower and display_lower not in AMBIGUOUS_TERMS:
        return 1

    # Single-word terms: check ambiguity
    if display_lower in AMBIGUOUS_TERMS:
        return 3

    # Remaining single-word terms that are game-specific enough
    # Conditions, kits, ancestries, complications with unique names
    return 2


def build_plural_forms(display: str) -> list[str]:
    """Generate likely plural forms for a term."""
    lower = display.lower()

    # Check irregular plurals first
    if lower in IRREGULAR_PLURALS:
        return IRREGULAR_PLURALS[lower]

    # Simple English plural rules
    forms = []
    if lower.endswith("y") and lower[-2] not in "aeiou":
        forms.append(lower[:-1] + "ies")
    elif lower.endswith(("s", "sh", "ch", "x", "z")):
        forms.append(lower + "es")
    elif lower.endswith("f"):
        forms.append(lower[:-1] + "ves")
    elif lower.endswith("fe"):
        forms.append(lower[:-2] + "ves")
    else:
        forms.append(lower + "s")

    return forms


def load_terms(scc_path: str, promote_terms: set[str] | None = None) -> list[LinkTerm]:
    """Load and classify all linkable terms from scc_to_path.json."""
    with open(scc_path) as f:
        scc_map = json.load(f)

    # Types worth linking in heroes prose
    linkable_types = {
        "condition", "movement", "kit", "class", "ancestry",
        "perk", "career", "complication", "skill", "title",
        "common-ability",
        # kit-ability excluded: terms like "fade", "battle grace" are too
        # context-dependent and collide with common prose
    }

    terms = []
    for key, path in scc_map.items():
        parts = key.split(":")
        if len(parts) < 3:
            continue

        full_type = parts[1]
        scc_type = full_type.split(".")[0]
        if scc_type not in linkable_types:
            continue

        # Skip class-level features (e.g., class.elementalist.level:basics)
        # These are individual class features with generic names
        if ".level" in full_type:
            continue

        item_slug = parts[2]
        display = item_slug.replace("-", " ")

        tier = classify_tier(display, scc_type, promote_terms=promote_terms)
        if tier == 0:
            continue

        plurals = build_plural_forms(display)
        terms.append(LinkTerm(
            display=display,
            scc_key=key,
            scc_type=scc_type,
            tier=tier,
            variants=plurals,
        ))

    return terms


# ---------------------------------------------------------------------------
# Markdown processing
# ---------------------------------------------------------------------------

def is_inside_link(line: str, match_start: int, match_end: int) -> bool:
    """Check if a match position falls inside an existing markdown link."""
    # Find all [...](...)  patterns
    for m in re.finditer(r'\[([^\]]*)\]\(([^)]*)\)', line):
        if m.start() <= match_start and match_end <= m.end():
            return True
    # Also check for **[...](...)**  bold-wrapped links
    for m in re.finditer(r'\*\*\[([^\]]*)\]\(([^)]*)\)\*\*', line):
        if m.start() <= match_start and match_end <= m.end():
            return True
    return False


def is_inside_bold_def(line: str, match_start: int) -> bool:
    """Check if match is in the bold-defined term of a glossary entry like **Term:**"""
    m = re.match(r'\*\*[^*]+:\*\*', line)
    if m and match_start < m.end():
        return True
    return False


def is_inside_quotes(line: str, match_start: int, match_end: int) -> bool:
    """Check if match is inside double quotes (e.g., creatures with "burrow" in their speed)."""
    # Find all quoted spans
    for m in re.finditer(r'"[^"]*"', line):
        if m.start() < match_start and match_end <= m.end():
            return True
    return False


def _possessive_pattern(escaped_form: str) -> str:
    """Expand an escaped form so possessive-s also matches apostrophe forms.

    Slugs drop apostrophes: "saints vigilance" should match both
    "Saints Vigilance" and "Saint's Vigilance".  We replace each
    ``s<space>`` with ``(?:'?s)<space>`` so the apostrophe before the
    trailing s is optional.
    """
    return re.sub(r"s(\\ )", r"(?:'?s)\1", escaped_form)


def build_pattern(term: LinkTerm) -> re.Pattern:
    """Build a regex pattern that matches the term and its variants."""
    forms = [_possessive_pattern(re.escape(term.display))]
    for v in term.variants:
        forms.append(_possessive_pattern(re.escape(v)))

    # Sort longest first to prefer longer matches
    forms.sort(key=len, reverse=True)

    # Word boundary matching, case insensitive
    # Also exclude hyphens to avoid matching inside compound words like "battle-scarred"
    pattern_str = r'(?<![\[\w\-])(' + '|'.join(forms) + r')(?![/\]\w\-])'
    return re.compile(pattern_str, re.IGNORECASE)


@dataclass
class LinkResult:
    """A proposed or applied link."""
    line_num: int
    original_text: str
    display_text: str
    scc_key: str
    tier: int
    context: str  # surrounding line for review


def process_file(
    md_path: str,
    terms: list[LinkTerm],
    max_tier: int = 2,
    dry_run: bool = False,
) -> tuple[list[str], list[LinkResult], list[LinkResult]]:
    """
    Process a markdown file and inject scc: links.

    Returns:
        (output_lines, applied_links, review_links)
    """
    with open(md_path, "r", encoding="utf-8") as f:
        lines = f.readlines()

    # Pre-compile patterns, sorted longest display first to avoid partial matches
    terms_sorted = sorted(terms, key=lambda t: len(t.display), reverse=True)
    compiled = [(t, build_pattern(t)) for t in terms_sorted]

    applied: list[LinkResult] = []
    review: list[LinkResult] = []
    output_lines = []

    in_frontmatter = False

    for line_idx, line in enumerate(lines):
        line_num = line_idx + 1
        stripped = line.lstrip()

        # Track frontmatter
        if stripped.startswith("---"):
            in_frontmatter = not in_frontmatter
            output_lines.append(line)
            continue

        # Skip frontmatter, headers, and blockquote headers (> ######)
        if in_frontmatter or stripped.startswith("#"):
            output_lines.append(line)
            continue
        bq_stripped = stripped.lstrip("> ").lstrip()
        if bq_stripped.startswith("#"):
            output_lines.append(line)
            continue

        # Skip blockquote list items (e.g., "> * Some content")
        if stripped.startswith("> * "):
            output_lines.append(line)
            continue

        # Process the line: replace terms that aren't already linked
        modified = line

        for term, pattern in compiled:
            # Find all matches in current state of modified line
            new_modified = ""
            last_end = 0

            for match in pattern.finditer(modified):
                start, end = match.start(), match.end()
                matched_text = match.group(0)

                # Skip if inside an existing link
                if is_inside_link(modified, start, end):
                    continue

                # Skip if in a bold definition header
                if is_inside_bold_def(modified, start):
                    continue

                # Skip if inside double quotes (speed entry references etc.)
                if is_inside_quotes(modified, start, end):
                    continue

                result = LinkResult(
                    line_num=line_num,
                    original_text=matched_text,
                    display_text=matched_text,
                    scc_key=term.scc_key,
                    tier=term.tier,
                    context=line.rstrip(),
                )

                if term.tier <= max_tier:
                    # Auto-link
                    replacement = f"[{matched_text}](scc:{term.scc_key})"
                    new_modified += modified[last_end:start] + replacement
                    last_end = end
                    applied.append(result)
                else:
                    # Tier 3: just record for review
                    review.append(result)

            if last_end > 0:
                new_modified += modified[last_end:]
                modified = new_modified

        output_lines.append(modified)

    return output_lines, applied, review


def write_report(report_path: str, review_links: list[LinkResult]):
    """Write a review report for tier 3 (ambiguous) terms."""
    if not review_links:
        return

    # Group by term
    by_term: dict[str, list[LinkResult]] = {}
    for r in review_links:
        key = r.scc_key
        if key not in by_term:
            by_term[key] = []
        by_term[key].append(r)

    with open(report_path, "w") as f:
        f.write("# SCC Auto-Linker Review Report\n\n")
        f.write(f"Total ambiguous occurrences: {len(review_links)}\n\n")

        for scc_key, results in sorted(by_term.items(), key=lambda x: -len(x[1])):
            f.write(f"## `{scc_key}` ({len(results)} occurrences)\n\n")
            for r in results[:20]:  # Cap at 20 examples per term
                ctx = r.context.strip()
                if len(ctx) > 120:
                    # Try to center around the match
                    idx = ctx.lower().find(r.original_text.lower())
                    if idx > 50:
                        ctx = "..." + ctx[idx - 40:]
                    if len(ctx) > 120:
                        ctx = ctx[:120] + "..."
                f.write(f"- L{r.line_num}: `{ctx}`\n")

            if len(results) > 20:
                f.write(f"- ... and {len(results) - 20} more\n")
            f.write("\n")


def clean_invalid_links(
    md_path: str,
    scc_map: dict[str, str],
    dry_run: bool = False,
) -> tuple[list[str], int]:
    """Remove scc: links whose keys are not in the current scc_to_path mapping.

    Returns:
        (output_lines, removed_count)
    """
    with open(md_path, "r", encoding="utf-8") as f:
        lines = f.readlines()

    scc_link_re = re.compile(r'\[([^\]]*)\]\(scc:([^)]+)\)')
    removed = 0
    output_lines = []

    for line in lines:
        def _replace(m: re.Match) -> str:
            nonlocal removed
            display_text = m.group(1)
            scc_key = m.group(2)
            if scc_key not in scc_map:
                removed += 1
                return display_text
            return m.group(0)

        output_lines.append(scc_link_re.sub(_replace, line))

    return output_lines, removed


def print_summary(applied: list[LinkResult], review: list[LinkResult]):
    """Print a summary of changes."""
    print(f"\nLinks applied: {len(applied)}")

    if applied:
        from collections import Counter
        by_type = Counter()
        for r in applied:
            parts = r.scc_key.split(":")
            by_type[parts[1].split(".")[0]] += 1
        print("  By type:")
        for typ, count in by_type.most_common():
            print(f"    {typ}: {count}")

    if review:
        print(f"\nTier 3 (review needed): {len(review)} occurrences")
        from collections import Counter
        by_term = Counter(r.scc_key for r in review)
        print("  Top ambiguous terms:")
        for term, count in by_term.most_common(10):
            slug = term.split(":")[-1]
            print(f"    {slug}: {count}")


def main():
    parser = argparse.ArgumentParser(description="SCC Auto-Linker for Draw Steel markdown")
    parser.add_argument("markdown_file", help="Path to the markdown file to process")
    parser.add_argument("scc_json", help="Path to scc_to_path.json")
    parser.add_argument("--dry-run", action="store_true", help="Don't modify the file, just report")
    parser.add_argument("--report", type=str, default=None, help="Path to write tier 3 review report")
    parser.add_argument("--tier", type=str, default="2",
                        help="Max tier to auto-apply: 1, 2, 3, or all (default: 2)")
    parser.add_argument("--term", type=str, default=None,
                        help="Promote a single tier-3 term for review. Uses the kebab-case "
                             "slug (e.g., 'noble', 'animal-form'). Implies --tier 2 so only "
                             "the promoted term (plus existing tier 1/2) is applied.")
    parser.add_argument("--clean", action="store_true",
                        help="Remove scc: links whose keys no longer exist in scc_to_path.json")
    args = parser.parse_args()

    # --clean mode: strip links with scc keys missing from the mapping
    if args.clean:
        with open(args.scc_json) as f:
            scc_map = json.load(f)
        print(f"Cleaning invalid scc: links in {args.markdown_file}...")
        print(f"  {len(scc_map)} keys in {args.scc_json}")
        output_lines, removed = clean_invalid_links(
            args.markdown_file, scc_map, dry_run=args.dry_run
        )
        print(f"  Removed {removed} invalid link(s)")
        if not args.dry_run and removed > 0:
            with open(args.markdown_file, "w", encoding="utf-8") as f:
                f.writelines(output_lines)
            print(f"  File updated: {args.markdown_file}")
        elif args.dry_run:
            print("  (Dry run -- no changes written)")
        return

    # --term implies tier 2: we promote the one term to tier 2 so it gets
    # auto-linked alongside the safe tiers, while everything else stays put.
    promote_terms: set[str] | None = None
    if args.term:
        # Convert slug to display form for matching
        promote_display = args.term.replace("-", " ").lower()
        promote_terms = {promote_display}
        max_tier = 2
        print(f"Single-term mode: promoting '{promote_display}' from tier 3 -> tier 2")
    else:
        max_tier = 3 if args.tier == "all" else int(args.tier)

    print(f"Loading SCC terms from {args.scc_json}...")
    terms = load_terms(args.scc_json, promote_terms=promote_terms)
    print(f"  Loaded {len(terms)} linkable terms")
    print(f"    Tier 1 (multi-word, auto): {sum(1 for t in terms if t.tier == 1)}")
    print(f"    Tier 2 (single-word, auto): {sum(1 for t in terms if t.tier == 2)}")
    print(f"    Tier 3 (ambiguous, review): {sum(1 for t in terms if t.tier == 3)}")

    # In --term mode, filter to only the promoted term so tier 1/2 don't
    # re-process already-linked content (they'd be skipped by is_inside_link
    # anyway, but this keeps output clean and fast).
    if promote_terms:
        terms = [t for t in terms if t.display.lower() in promote_terms]
        if not terms:
            print(f"\nError: no linkable term found for slug '{args.term}'")
            sys.exit(1)
        print(f"  Filtered to {len(terms)} term(s): {[t.display for t in terms]}")

    print(f"\nProcessing {args.markdown_file} (max_tier={max_tier})...")
    output_lines, applied, review = process_file(
        args.markdown_file, terms, max_tier=max_tier, dry_run=args.dry_run
    )

    print_summary(applied, review)

    if args.report:
        write_report(args.report, review)
        print(f"\nReview report written to {args.report}")

    if not args.dry_run and applied:
        with open(args.markdown_file, "w", encoding="utf-8") as f:
            f.writelines(output_lines)
        print(f"\nFile updated: {args.markdown_file}")
    elif args.dry_run:
        print("\n(Dry run -- no changes written)")


if __name__ == "__main__":
    main()
