#!/usr/bin/env python3
"""
Review and clean ambiguous scc: links injected by scc-auto-linker.py --term.

For each ambiguous link, determines whether it references the actual game
rule/mechanic or is just a common English word used in prose. Strips links
that are prose usage, keeping those that are genuine rule references.
"""

import re
import sys
import json
from collections import Counter

# ---------------------------------------------------------------------------
# Load ambiguous terms from linker
# ---------------------------------------------------------------------------

def load_ambiguous_terms(linker_path: str) -> set[str]:
    with open(linker_path) as f:
        source = f.read()
    match = re.search(r'AMBIGUOUS_TERMS\s*=\s*\{([^}]+)\}', source, re.DOTALL)
    return set(re.findall(r'"([^"]+)"', match.group(1)))

# ---------------------------------------------------------------------------
# Terms that should ALWAYS be unlinked (too generic, never a rule reference)
# ---------------------------------------------------------------------------

# These are common English words where virtually every usage in the book is
# prose, not a game-term reference. Even when they happen to match a feature
# name, the reader would not benefit from a link.
ALWAYS_REMOVE = {
    "one",          # the number / pronoun -- 1400+ false positives
    "again",        # adverb
    "friend",       # common word
    "mundane",      # common adjective
    "foil",         # common word / narrative term
    "blocking",     # common gerund
    "lucky",        # common adjective
    "foreshadowing",# narrative term
    "loner",        # common word
    "take two",     # too generic
    "when a creature moves",  # sentence fragment, not a term name
    "goaded",       # common participle
    "spotlight",    # common word
}

# ---------------------------------------------------------------------------
# Context-based heuristics
# ---------------------------------------------------------------------------

def is_glossary_def(line: str, match_obj: re.Match) -> bool:
    """Check if the link is in a **[Term](scc:...):** glossary definition."""
    start = match_obj.start()
    # Look for ** before the [
    prefix = line[:start]
    if prefix.rstrip().endswith("**"):
        return False  # that's a closing bold, not opening
    # Check if **[ pattern precedes
    if re.search(r'\*\*\s*$', prefix):
        return True
    # Check for **[Term](...)**:  or **[Term](...):**
    full_pattern = re.compile(r'\*\*\[' + re.escape(match_obj.group(1)) + r'\]\([^)]+\)\*?\*?:')
    if full_pattern.search(line):
        return True
    return False


def is_class_reference(line: str, match_obj: re.Match, display_lower: str, scc_type: str) -> bool:
    """Check if this is a class/ancestry reference like 'the [fury]'s' or 'a [conduit] hero'."""
    if scc_type not in ("class", "ancestry"):
        return False
    start = match_obj.start()
    end = match_obj.end()
    prefix = line[:start].lower()
    suffix = line[end:end+30].lower()

    # Negative: "[class] elves" or "[class]-magics" -- modifier usage, not class ref
    if re.search(r'^[\-]|^\s+(elves?|elf|magics?|born)\b', suffix):
        # Exception: "Shadow Born" in a table is a complication name
        if not re.search(r'^\s+born\s*\|', suffix):
            return False

    # Negative: literal/metaphorical shadow usage
    literal_prefix = [
        r'\bin\s+(their|the|its|a|your|his|her)\s+$',
        r'\bcast\s+a\s+$',
        r'\binto\s+(the\s+)?$',
        r"\bsun's\s+$",
        r'\bactual\s+$',
        r'\bmanipulate\s+$',
        r'\band\s+$',       # "spells and shadows"
        r'\bforgotten\s+$', # "forgotten shadows of history"
    ]
    for pat in literal_prefix:
        if re.search(pat, prefix):
            # Exception: "and [class]" in a list of classes is valid
            if pat == r'\band\s+$' and re.search(r'\(scc:[^)]*:class:[^)]+\)', prefix[-80:]):
                continue
            return False

    # Negative: "of Shadows" in a title/name context (Queen of Shadows)
    if re.search(r'\bof\s+$', prefix) and display_lower in ("shadow", "shadows"):
        return False

    # Negative: "shadows of history", "shadows and wizards" in prose
    if re.search(r'^\s+(of\s+(history|the|time|night|dark))', suffix):
        return False

    # "the [class]" or "a [class]" or "your [class]"
    if re.search(r'\b(the|a|an|your|their|each|every|as)\s+$', prefix):
        return True
    # "[Class]'s" possessive
    if suffix.startswith("'s") or suffix.startswith("\u2019s"):
        return True
    # "playing a [class]" or "is a [class]"
    if re.search(r'\b(play|playing|is|are|become|becomes)\s+(a\s+)?$', prefix):
        return True
    # "As a Nth-level [class]" pattern
    if re.search(r'\b(as\s+a\s+)?\d+(st|nd|rd|th)[- ]level\s+$', prefix):
        return True
    # "1st-level [class] college/ability/feature" patterns
    if re.search(r'^\s+(college|abilit|feature|hero)', suffix):
        return True
    # Class name in a comma-separated list with other scc links nearby
    if re.search(r'\(scc:[^)]*:class:[^)]+\)', line[:start][-80:]) or \
       re.search(r'\(scc:[^)]*:class:[^)]+\)', line[end:end+80]):
        return True
    # "crafted by a [class]" or similar agent references
    if re.search(r'\bby\s+a\s+$', prefix):
        return True
    return False


def is_resource_reference(line: str, match_obj: re.Match, display_lower: str, scc_type: str) -> bool:
    """Check if this references a Heroic Resource by name (e.g., 'your focus', 'gain piety')."""
    resource_terms = {
        "focus", "piety", "ferocity", "essence", "discipline",
        "insight", "wrath", "drama", "vision", "command",
        "clarity", "judgment", "judgement", "virtue",
    }
    if display_lower not in resource_terms:
        return False

    start = match_obj.start()
    end = match_obj.end()
    prefix = line[:start].lower()
    suffix = line[end:end+30].lower()

    # Mechanical resource patterns
    resource_patterns_prefix = [
        r'\b(gain|lose|spend|earn|have|your|their|the|with|of|extra|max|maximum|starting)\s+$',
        r'\b(regain|recover|at|current|bonus)\s+$',
        r'\bpoints?\s+of\s+$',
    ]
    resource_patterns_suffix = [
        r'^\s*(points?|score|pool|bonus|equal|increases?|decreases?|drops?|reaches?)',
        r'^\s*[\.,;:\)]',
        r'^\s+\d',  # followed by a number
    ]

    for pat in resource_patterns_prefix:
        if re.search(pat, prefix):
            return True
    for pat in resource_patterns_suffix:
        if re.search(pat, suffix):
            return True

    return False


def is_mechanical_movement(line: str, match_obj: re.Match, display_lower: str, scc_type: str) -> bool:
    """Check if this is a mechanical movement reference (speed entry, 'can fly', etc.)."""
    if scc_type != "movement":
        return False

    start = match_obj.start()
    end = match_obj.end()
    prefix = line[:start].lower()
    suffix = line[end:end+30].lower()

    movement_prefix = [
        r'\b(can|can\'t|cannot|can not|to|must|mode|speed|and|or)\s+$',
        r'\bmovement\s+(mode|to)\s+$',
        r'\bsquares?\s+of\s+$',
    ]
    movement_suffix = [
        r'^\s*(speed|movement|mode|squares?|[\.,;])',
        r'^\s*\d',  # "fly 5"
    ]

    for pat in movement_prefix:
        if re.search(pat, prefix):
            return True
    for pat in movement_suffix:
        if re.search(pat, suffix):
            return True

    return False


def is_ability_reference(line: str, match_obj: re.Match, display_lower: str, scc_type: str) -> bool:
    """Check if this is a reference to a game ability (maneuver/action)."""
    ability_terms = {
        "grab", "hide", "charge", "defend", "heal", "ride",
        "advance", "disengage", "teleport",
    }
    if display_lower not in ability_terms:
        return False

    start = match_obj.start()
    end = match_obj.end()
    prefix = line[:start].lower()
    suffix = line[end:end+30].lower()
    display = match_obj.group(1)

    # Capitalized in mid-sentence -> likely game term
    if display[0].isupper() and start > 0 and line[start-1] != '.':
        after_period = re.search(r'[.!?]\s+$', prefix)
        if not after_period:
            return True

    # "use [ability]", "make a [ability]", "the [ability] action/maneuver"
    ability_prefix = [
        r'\b(use|using|make|making|takes?|took|perform|the)\s+(a\s+)?$',
        r'\b(an?|the)\s+$',
    ]
    ability_suffix = [
        r'^\s*(action|maneuver|ability|keyword|roll|test|check)',
    ]

    for pat in ability_prefix:
        if re.search(pat, prefix):
            for spat in ability_suffix:
                if re.search(spat, suffix):
                    return True

    # Capitalized standalone references in mechanical text
    if display[0].isupper():
        # Check if line has other scc links (mechanical context)
        other_links = re.findall(r'\(scc:[^)]+\)', line)
        if len(other_links) >= 2:
            return True

    return False


def is_kit_perk_career_reference(line: str, match_obj: re.Match, display_lower: str, scc_type: str) -> bool:
    """Check if this is a reference to a specific kit/perk/career by name."""
    if scc_type not in ("kit", "perk", "career", "complication", "title"):
        return False

    start = match_obj.start()
    end = match_obj.end()
    prefix = line[:start].lower()
    suffix = line[end:end+30].lower()
    display = match_obj.group(1)

    # Glossary-style: "**[Term](scc:...):**"
    # Already handled by is_glossary_def

    # Capitalized in mid-sentence (not after period) -> likely named reference
    if display[0].isupper() and start > 2:
        before = line[:start].rstrip()
        if before and before[-1] not in '.!?':
            return True

    # "the [Kit] kit" or "[Kit] perk" or "[Career] career"
    type_suffix = [
        r'^\s*(kit|perk|career|complication|title)\b',
    ]
    for pat in type_suffix:
        if re.search(pat, suffix):
            return True

    # After "the" with capitalization
    if re.search(r'\bthe\s+$', prefix) and display[0].isupper():
        return True

    return False


def is_subclass_feature_reference(line: str, match_obj: re.Match, display_lower: str, scc_key: str) -> bool:
    """Check if this references a specific class feature/subclass trait."""
    if "feature" not in scc_key:
        return False

    start = match_obj.start()
    display = match_obj.group(1)

    # Capitalized in mid-sentence -> likely referencing the named feature
    if display[0].isupper() and start > 2:
        before = line[:start].rstrip()
        if before and before[-1] not in '.!?':
            return True

    return False


def should_keep_link(line: str, match_obj: re.Match, scc_key: str, ambig_terms: set) -> bool:
    """Master decision: should this ambiguous link be kept?"""
    display = match_obj.group(1)
    display_lower = display.lower()
    slug = scc_key.split(":")[-1].replace("-", " ")

    # Only review ambiguous terms
    if slug not in ambig_terms:
        return True  # not our problem

    # Always remove these
    if display_lower in ALWAYS_REMOVE:
        return False

    # Extract scc type
    parts = scc_key.split(":")
    scc_type = parts[1].split(".")[0] if len(parts) >= 2 else ""

    # Glossary definition -> always keep
    if is_glossary_def(line, match_obj):
        return True

    # "skill"/"skills" -- the Talent 10th-level feature named "Skill"
    # Almost never a reference to that feature; it's the generic concept
    if display_lower in ("skill", "skills"):
        # Only keep in glossary defs (already handled above)
        # and when clearly about the Talent feature specifically
        prefix = line[:match_obj.start()].lower()
        if "talent" in prefix[-60:]:
            return True
        return False

    # "kit" -- very common game term but usually refers to the concept, not a specific link target
    if display_lower in ("kit", "kits"):
        # Keep when capitalized mid-sentence or in mechanical reference
        if display[0].isupper() and match_obj.start() > 2:
            before = line[:match_obj.start()].rstrip()
            if before and before[-1] not in '.!?':
                return True
        # "a kit", "the kit", "your kit", "each kit" -> generic concept, keep
        prefix = line[:match_obj.start()].lower()
        if re.search(r'\b(a|the|your|their|each|every|this|that|new|same|chosen|select|specific|different)\s+$', prefix):
            return True
        # "kit's" possessive
        suffix = line[match_obj.end():match_obj.end()+5]
        if suffix.startswith("'s"):
            return True
        return False

    # "perk" / "perks" -- game concept
    if display_lower in ("perk", "perks"):
        # Usually a valid game term reference in this book
        return True

    # "triggered action" / "triggered actions" -- game mechanic
    if display_lower in ("triggered action", "triggered actions"):
        return True

    # "signature ability" / "signature abilities" -- game mechanic
    if display_lower in ("signature ability", "signature abilities"):
        return True

    # "heroic ability" / "heroic abilities" -- game mechanic
    if display_lower in ("heroic ability", "heroic abilities"):
        return True

    # "characteristic increase" -- game mechanic
    if display_lower == "characteristic increase":
        return True

    # "divine power" / "primordial power" -- game mechanic
    if display_lower in ("divine power", "primordial power"):
        return True

    # "protective circle" -- specific enough
    if display_lower == "protective circle":
        return True

    # "null field" -- game mechanic
    if display_lower == "null field":
        return True

    # "hit and run" -- game mechanic
    if display_lower == "hit and run":
        return True

    # "to the death" -- specific enough
    if display_lower == "to the death":
        return True

    # "tooth and claw" -- specific feature name
    if display_lower == "tooth and claw":
        return True

    # "stand fast" -- specific ability
    if display_lower == "stand fast":
        return True

    # "when a creature moves" -- too generic
    if display_lower == "when a creature moves":
        return False

    # "focus outside of combat" -- too generic phrase
    if display_lower == "focus outside of combat":
        return False

    # Class name references
    if is_class_reference(line, match_obj, display_lower, scc_type):
        return True

    # Resource references
    if is_resource_reference(line, match_obj, display_lower, scc_type):
        return True

    # Movement references
    if is_mechanical_movement(line, match_obj, display_lower, scc_type):
        return True

    # Ability references
    if is_ability_reference(line, match_obj, display_lower, scc_type):
        return True

    # Kit/perk/career references
    if is_kit_perk_career_reference(line, match_obj, display_lower, scc_type):
        return True

    # Subclass feature references (capitalized)
    if is_subclass_feature_reference(line, match_obj, display_lower, scc_key):
        return True

    # DEFAULT: if it's a feature and lowercase, likely prose usage
    if "feature" in scc_key and display[0].islower():
        return False

    # Ancestry names that are real-world words: in a TTRPG book, lowercase
    # "humans" and "devils" almost always reference the game ancestry.
    # Only remove for clearly non-ancestry usage (adjectives, idioms).
    LENIENT_ANCESTRIES = {"human", "humans", "devil", "devils"}
    if display_lower in LENIENT_ANCESTRIES and scc_type == "ancestry":
        # Remove adjectival uses: "human civilization", "devil worship"
        suffix = line[match_obj.end():match_obj.end()+30].lower()
        adj_nouns = r'^\s+(civilization|society|politics|nature|history|sacrifice|worship|form|looking|realm)'
        if re.search(adj_nouns, suffix):
            return False
        # Otherwise keep -- it's a game ancestry reference
        return True

    # Ancestry / class names lowercase in prose -> remove
    if scc_type in ("class", "ancestry") and display[0].islower():
        return False

    # Career/complication/title lowercase in prose -> remove
    if scc_type in ("career", "complication", "title") and display[0].islower():
        return False

    # Movement terms: teleport/fly/hover are almost always mechanical in a TTRPG book.
    # walk/jump/swim/climb/vertical are more ambiguous.
    LENIENT_MOVEMENTS = {"teleport", "teleported", "teleports", "teleporting",
                         "fly", "flying", "flies",
                         "hover", "hovering",
                         "crawl", "crawling",
                         "disengage", "disengaging"}
    if scc_type == "movement" and display_lower in LENIENT_MOVEMENTS:
        # Only remove for clearly non-mechanical usage
        prefix = line[:match_obj.start()].lower()
        # "on the fly" idiom
        if display_lower in ("fly", "flying") and re.search(r'\bon\s+the\s+$', prefix):
            return False
        return True

    # Remaining movement lowercase in general prose -> remove
    if scc_type == "movement" and display[0].islower():
        return False

    # Common abilities: in a TTRPG rulebook, "grab", "hide", "charge" etc. are
    # usually referring to the game action. Only remove clear idioms/prose.
    if scc_type == "common-ability":
        prefix = line[:match_obj.start()].lower()
        suffix = line[match_obj.end():match_obj.end()+30].lower()

        # Idiom removals for specific terms
        if display_lower in ("charge", "charges"):
            # "in charge (of)" = prose idiom
            if re.search(r'\bin\s+$', prefix):
                return False
            # "who's/what's in charge" pattern
            if re.search(r"'s\s+in\s+$", prefix):
                return False
        if display_lower in ("hide", "hides", "hiding"):
            # "nothing to hide", "something to hide"
            if re.search(r'\b(nothing|something|anything)\s+to\s+$', prefix):
                return False
            # "hide from justice/the truth" = prose
            if re.search(r'^\s+from\s+(justice|the\s+truth|their)', suffix):
                return False
        if display_lower in ("grab", "grabs", "grabbing"):
            # "grab two dice", "grab his staff" = prose (non-creature objects)
            if re.search(r'^\s+(two|ten|his|her|some)\s', suffix):
                return False
            # "claws grab the weak" in flavor text (italic context)
            if re.search(r'\*[^*]*$', line[:match_obj.start()]):
                return False
        if display_lower in ("heal", "heals", "healing"):
            # "heal" as common verb in narrative
            if re.search(r'\b(wounds?\s+)?$', prefix) and re.search(r'^\s*(wounds?|injuries|scars)', suffix):
                return False
        if display_lower in ("defend", "defends", "defending"):
            # "defend the/your [non-game-term]"
            if re.search(r'^\s+(the|your|their|his|her)\s+(city|town|home|kingdom|realm|people|honor)', suffix):
                return False
        if display_lower in ("advance", "advances", "advancing"):
            # Common verb in narrative: "advance toward/through/on"
            if re.search(r'^\s*(toward|through|on\s+the|into)', suffix):
                return False
        # Default: keep (it's a game action reference in rules context)
        return True

    # If capitalized, lean toward keeping (likely an intentional game reference)
    if display[0].isupper():
        return True

    # Default: remove (ambiguous and lowercase)
    return False


def process_file(md_path: str, ambig_terms: set, dry_run: bool = False):
    """Process a file, removing ambiguous links that are prose usage."""
    with open(md_path, "r", encoding="utf-8") as f:
        content = f.read()

    link_re = re.compile(r'\[([^\]]*)\]\(scc:([^)]+)\)')
    kept = Counter()
    removed = Counter()
    changes = []

    lines = content.split('\n')
    output_lines = []

    for line_idx, line in enumerate(lines):
        new_line = line
        offset = 0

        for m in link_re.finditer(line):
            display = m.group(1)
            scc_key = m.group(2)
            slug = scc_key.split(":")[-1].replace("-", " ")

            if slug not in ambig_terms:
                continue

            keep = should_keep_link(line, m, scc_key, ambig_terms)

            if keep:
                kept[slug] += 1
            else:
                removed[slug] += 1
                # Replace [display](scc:key) with just display
                old = m.group(0)
                adj_start = m.start() + offset
                adj_end = m.end() + offset
                new_line = new_line[:adj_start] + display + new_line[adj_end:]
                offset += len(display) - len(old)
                changes.append((line_idx + 1, slug, display, line.strip()[:100]))

        output_lines.append(new_line)

    new_content = '\n'.join(output_lines)

    # Summary
    total_kept = sum(kept.values())
    total_removed = sum(removed.values())
    print(f"\n{'='*60}")
    print(f"SUMMARY")
    print(f"{'='*60}")
    print(f"Links kept:    {total_kept}")
    print(f"Links removed: {total_removed}")
    print(f"{'='*60}")

    print(f"\nREMOVED by term:")
    for term, count in removed.most_common():
        k = kept.get(term, 0)
        print(f"  {count:4d} removed / {k:4d} kept  --  {term}")

    print(f"\nKEPT by term:")
    for term, count in kept.most_common():
        r = removed.get(term, 0)
        print(f"  {count:4d} kept / {r:4d} removed  --  {term}")

    if not dry_run:
        with open(md_path, "w", encoding="utf-8") as f:
            f.write(new_content)
        print(f"\nFile updated: {md_path}")
    else:
        print(f"\n(Dry run -- no changes written)")

    return total_kept, total_removed


if __name__ == "__main__":
    import argparse
    parser = argparse.ArgumentParser()
    parser.add_argument("markdown_file")
    parser.add_argument("--linker", default="etl/link_md/scc-auto-linker.py")
    parser.add_argument("--dry-run", action="store_true")
    args = parser.parse_args()

    ambig = load_ambiguous_terms(args.linker)
    process_file(args.markdown_file, ambig, dry_run=args.dry_run)
