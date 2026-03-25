#!/usr/bin/env python3
"""
Auto-link game terms in Draw Steel Heroes markdown using scc: URIs.

Usage:
    python3 scripts/autolink.py "input/heroes/Draw Steel Heroes.md" [--dry-run] [--review]

--dry-run: Print stats without modifying the file
--review:  Output a diff-style review of dangerous-tier changes to stderr
"""

import re
import sys
from dataclasses import dataclass, field
from pathlib import Path


# ---------------------------------------------------------------------------
# Term Registry
# ---------------------------------------------------------------------------

@dataclass
class Term:
    display: str               # canonical display name (e.g., "Dragon Knight")
    uri: str                   # scc: URI
    tier: str = "safe"         # safe | contextual | dangerous
    aliases: list[str] = field(default_factory=list)  # alternate display forms

    @property
    def all_forms(self) -> list[str]:
        return [self.display] + self.aliases


def _id(name: str) -> str:
    """Convert display name to URI slug: lowercase, spaces to hyphens, drop apostrophes."""
    return re.sub(r"['\u2019]", "", name).lower().replace(" ", "-")


def _t(display, type_path, tier="safe", aliases=None):
    """Shorthand to create a Term."""
    uri = f"scc:mcdm.heroes.v1:{type_path}:{_id(display)}"
    return Term(display=display, uri=uri, tier=tier, aliases=aliases or [])


# --- Build the registry ---

TERMS: list[Term] = []

# Ancestries
for name in ["Devil", "Dragon Knight", "Dwarf", "Hakaan", "High Elf", "Human",
             "Memonek", "Orc", "Polder", "Revenant", "Time Raider", "Wode Elf"]:
    tier = "dangerous" if name in ("Human", "Devil") else "safe"
    aliases = []
    if name == "Dwarf":
        aliases = ["dwarves", "dwarven"]
    elif name == "High Elf":
        aliases = ["high elves"]
    elif name == "Wode Elf":
        aliases = ["wode elves"]
    elif name == "Orc":
        aliases = ["orcs"]
    elif name == "Devil":
        aliases = ["devils"]
    elif name == "Polder":
        aliases = ["polders"]
    elif name == "Memonek":
        aliases = ["memoneks"]
    elif name == "Hakaan":
        aliases = ["hakaans"]
    elif name == "Revenant":
        aliases = ["revenants"]
    elif name == "Dragon Knight":
        aliases = ["dragon knights"]
    elif name == "Time Raider":
        aliases = ["time raiders"]
    TERMS.append(_t(name, "ancestry", tier=tier, aliases=aliases))

# Classes
for name in ["Censor", "Conduit", "Elementalist", "Fury", "Null", "Shadow",
             "Tactician", "Talent", "Troubadour"]:
    tier = "dangerous" if name in ("Fury", "Null", "Shadow", "Talent") else "safe"
    TERMS.append(_t(name, "class", tier=tier))

# Conditions
for name in ["Bleeding", "Dazed", "Frightened", "Grabbed", "Prone",
             "Restrained", "Slowed", "Taunted", "Weakened"]:
    # Conditions are used heavily in mechanical text -- contextual tier
    tier = "contextual"
    TERMS.append(_t(name, "condition", tier=tier))

# Careers
for name, tier in [
    ("Agent", "dangerous"), ("Aristocrat", "dangerous"), ("Artisan", "dangerous"),
    ("Beggar", "dangerous"), ("Criminal", "dangerous"), ("Disciple", "dangerous"),
    ("Explorer", "dangerous"), ("Farmer", "dangerous"), ("Gladiator", "contextual"),
    ("Laborer", "dangerous"), ("Mages Apprentice", "safe"),
    ("Performer", "dangerous"), ("Politician", "dangerous"), ("Sage", "dangerous"),
    ("Sailor", "dangerous"), ("Soldier", "dangerous"), ("Warden", "dangerous"),
    ("Watch Officer", "safe"),
]:
    TERMS.append(_t(name, "career", tier=tier))

# Kits
for name in ["Arcane Archer", "Battlemind", "Cloak and Dagger", "Dual Wielder",
             "Guisarmier", "Martial Artist", "Mountain", "Panther", "Pugilist",
             "Raider", "Ranger", "Rapid Fire", "Retiarius", "Shining Armor",
             "Sniper", "Spellsword", "Stick and Robe", "Swashbuckler",
             "Sword and Board", "Warrior Priest", "Whirlwind"]:
    tier = "dangerous" if name in ("Mountain", "Panther", "Ranger", "Sniper",
                                    "Raider", "Whirlwind") else "safe"
    TERMS.append(_t(name, "kit", tier=tier))

# Complications
COMPLICATIONS = [
    "Advanced Studies", "Amnesia", "Animal Form", "Antihero", "Artifact Bonded",
    "Bereaved", "Betrothed", "Chaos Touched", "Chosen One", "Consuming Interest",
    "Corrupted Mentor", "Coward", "Crash Landed", "Cult Victim",
    "Curse of Caution", "Curse of Immortality", "Curse of Misfortune",
    "Curse of Poverty", "Curse of Punishment", "Curse of Stone", "Cursed Weapon",
    "Disgraced", "Dragon Dreams", "Elemental Inside", "Evanesceria", "Exile",
    "Fallen Immortal", "Famous Relative", "Feytouched", "Fiery Ideal",
    "Fire and Chaos", "Following in the Footsteps", "Forbidden Romance",
    "Frostheart", "Getting Too Old for This", "Gnoll Mauled", "Greening",
    "Grifter", "Grounded", "Guilty Conscience", "Hawk Rider", "Host Body",
    "Hunted", "Hunter", "Indebted", "Infernal Contract",
    "Infernal Contract But Like Bad", "Ivory Tower", "Lifebonded",
    "Lightning Soul", "Loner", "Lost in Time", "Lost Your Head", "Lucky",
    "Master Chef", "Medusa Blood", "Medium", "Meddling Butler", "Misunderstood",
    "Mundane", "Outlaw", "Pirate", "Preacher", "Primordial Sickness",
    "Prisoner of the Synlirii", "Promising Apprentice", "Raised by Beasts",
    "Refugee", "Rival", "Rogue Talent", "Runaway", "Searching for a Cure",
    "Secret Identity", "Secret Twin", "Self Taught", "Sewer Folk", "Shadow Born",
    "Shattered Legacy", "Shipwrecked", "Siblings Shield", "Silent Sentinel",
    "Slight Case of Lycanthropy", "Stolen Face", "Strange Inheritance",
    "Stripped of Rank", "Shared Spirit", "Thrill Seeker", "Vampire Scion",
    "Voice in Your Head", "Vow of Duty", "Vow of Honesty", "Waking Dreams",
    "Ward", "War Dog Collar", "War of Assassins", "Waterborn", "Wodewalker",
    "Wrathful Spirit", "Wrongly Imprisoned",
]
# Short/common words that are dangerous as complications
DANGEROUS_COMPLICATIONS = {
    "Coward", "Exile", "Grounded", "Hunted", "Hunter", "Indebted", "Loner",
    "Lucky", "Medium", "Mundane", "Outlaw", "Pirate", "Preacher", "Refugee",
    "Rival", "Runaway", "Ward",
}
for name in COMPLICATIONS:
    tier = "dangerous" if name in DANGEROUS_COMPLICATIONS else "safe"
    TERMS.append(_t(name, "complication", tier=tier))

# Movement -- most are common English words, so dangerous tier
# Only "teleport" and "burrow" are game-specific enough for contextual
MOVEMENT_CONTEXTUAL = {"Teleport", "Burrow"}
for name in ["Burrow", "Climb or Swim", "Crawl", "Fly", "Hover", "Jump",
             "Teleport", "Walk"]:
    tier = "contextual" if name in MOVEMENT_CONTEXTUAL else "dangerous"
    aliases = []
    if name == "Climb or Swim":
        aliases = ["climb", "swim", "climbing", "swimming"]
    elif name == "Fly":
        aliases = ["flying", "flies"]
    elif name == "Walk":
        aliases = ["walking"]
    elif name == "Teleport":
        aliases = ["teleporting", "teleports"]
    elif name == "Burrow":
        aliases = ["burrowing", "burrows"]
    elif name == "Jump":
        aliases = ["jumping", "jumps"]
    elif name == "Hover":
        aliases = ["hovering", "hovers"]
    elif name == "Crawl":
        aliases = ["crawling", "crawls"]
    TERMS.append(_t(name, "movement", tier=tier, aliases=aliases))

# Perks
PERKS = {
    "crafting": ["Area of Expertise", "Expert Artisan", "Handy",
                 "Improvisation Creation", "Inspired Artisan", "Traveling Artisan"],
    "exploration": ["Brawny", "Camouflage Hunter", "Danger Sense",
                    "Friend Catapult", "Ive Got You", "Monster Whisperer",
                    "Put Your Back Into It", "Team Leader", "Teamwork", "Wood Wise"],
    "interpersonal": ["Charming Liar", "Dazzler", "Engrossing Monologue",
                      "Harmonizer", "Lie Detector", "Open Book",
                      "Pardon My Friend", "Power Player", "So Tell Me",
                      "Spot the Tell"],
    "intrigue": ["Criminal Contacts", "Forgettable Face", "Gum Up the Works",
                 "Lucky Dog", "Master of Disguise", "Slipped Lead"],
    "lore": ["But I Know Who Does", "Eidetic Memory", "Expert Sage",
             "Ive Read About This Place", "Linguist", "Polymath", "Specialist",
             "Traveling Sage"],
    "supernatural": ["Arcane Trick", "Creature Sense", "Familiar",
                     "Invisible Force", "Psychic Whisper", "Ritualist",
                     "Thingspeaker"],
}
DANGEROUS_PERKS = {"Handy", "Familiar", "Specialist", "Linguist", "Polymath",
                   "Teamwork", "Dazzler", "Open Book"}
for category, names in PERKS.items():
    for name in names:
        tier = "dangerous" if name in DANGEROUS_PERKS else "safe"
        TERMS.append(_t(name, f"perk.{category}", tier=tier))

# Titles
TITLES = {
    "1st-echelon": [
        "Ancient Loremaster", "Battleaxe Diplomat", "Brawler", "City Rat",
        "Doomed", "Dwarven Legionnaire", "Elemental Dabbler", "Faction Member",
        "Local Hero", "Mage Hunter", "Marshal", "Monster Bane", "Owed a Favor",
        "Presumed Dead", "Ratcatcher", "Saved for a Worse Fate", "Ship Captain",
        "Troupe Leading Player", "Wanted Dead or Alive", "Zombie Slayer",
    ],
    "2nd-echelon": [
        "Arena Fighter", "Awakened", "Battlefield Commander", "Blood Magic",
        "Corsair", "Faction Officer", "Fey Friend", "Giant Slayer", "Godsworn",
        "Heist Hero", "Knight", "Master Librarian", "Special Agent",
        "Sworn Hunter", "Undead Slain", "Unstoppable",
    ],
    "3rd-echelon": [
        "Armed and Dangerous", "Back From the Grave", "Demon Slayer",
        "Diabolist", "Dragon Blooded", "Fleet Admiral", "Maestro",
        "Master Crafter", "Noble", "Planar Voyager", "Scarred",
        "Siege Breaker", "Teacher",
    ],
    "4th-echelon": [
        "Champion Competitor", "Demigod", "Enlightened", "Forsaken", "Monarch",
        "Peace Bringer", "Reborn", "Theoretical Warrior", "Tireless", "Unchained",
    ],
}
DANGEROUS_TITLES = {
    "Brawler", "Doomed", "Marshal", "Knight", "Unstoppable", "Awakened",
    "Noble", "Scarred", "Teacher", "Enlightened", "Forsaken", "Monarch",
    "Reborn", "Tireless",
}
for echelon, names in TITLES.items():
    for name in names:
        tier = "dangerous" if name in DANGEROUS_TITLES else "safe"
        TERMS.append(_t(name, f"title.{echelon}", tier=tier))

# Chapters -- omitted from auto-linking; these are common English words
# (combat, tests, rewards, etc.) and should be linked manually when
# referring to the actual chapter.  Left as a comment for reference:
# Ancestries, Background, Classes, Combat, Complications, Downtime Projects,
# For the Director, Gods and Religion, Introduction, Kits, Making a Hero,
# Negotiation, Perks, Rewards, Tests, The Basics

# Skills (category-level only)
for name in ["Crafting Skills", "Exploration Skills", "Interpersonal Skills",
             "Intrigue Skills", "Lore Skills"]:
    TERMS.append(_t(name, "skill", tier="safe"))


# ---------------------------------------------------------------------------
# Linking Engine
# ---------------------------------------------------------------------------

# Pre-compile: sort terms longest-first to avoid partial matches
TERMS.sort(key=lambda t: max(len(f) for f in t.all_forms), reverse=True)


def _build_pattern(term: Term) -> re.Pattern:
    """Build a regex that matches any form of the term, case-insensitive,
    with word boundaries, but NOT inside an existing markdown link."""
    forms = sorted(term.all_forms, key=len, reverse=True)
    escaped = [re.escape(f) for f in forms]
    alternation = "|".join(escaped)
    # Word boundary match, case insensitive
    return re.compile(rf"\b({alternation})\b", re.IGNORECASE)


def _is_inside_link(text: str, match_start: int, match_end: int) -> bool:
    """Check if a match position is inside an existing markdown link [text](url)."""
    # Check if we're inside [...](...) by scanning backwards for unmatched [
    # and forwards for ](...)
    depth = 0
    for i in range(match_start - 1, max(match_start - 300, -1), -1):
        if text[i] == ']':
            depth += 1
        elif text[i] == '[':
            if depth > 0:
                depth -= 1
            else:
                # We're inside a [ ... ] -- check if it's a link
                # Look ahead from match_end for ](
                remaining = text[match_end:]
                # Could be more link text after us before the ]
                close_bracket = text.find(']', match_end)
                if close_bracket != -1 and close_bracket < match_end + 200:
                    after = text[close_bracket:]
                    if after.startswith(']('):
                        return True
                return True  # Inside brackets regardless
        elif text[i] == '\n':
            break

    # Also check if we're inside the URL part of a link: ](...)
    for i in range(match_start - 1, max(match_start - 500, -1), -1):
        if text[i] == '(':
            # Check if preceded by ](
            if i > 0 and text[i-1] == ']':
                # We're inside the URL portion
                return True
            break
        elif text[i] in ('\n', ')'):
            break

    return False


def _is_in_header(line: str) -> bool:
    """Check if a line is a markdown header."""
    return line.lstrip().startswith('#')


def _is_in_bold_def(line: str, match_start_in_line: int) -> bool:
    """Check if the match is the bold-defined term at the start of a glossary entry.
    Pattern: **Term:** or **[Term](uri):** at line start."""
    stripped = line.lstrip()
    if stripped.startswith('**'):
        # This is a bold definition line -- the bold term itself should be
        # linked (if not already), but we need to be careful
        # Find the closing **
        close = stripped.find('**', 2)
        if close != -1:
            bold_section = stripped[2:close]
            # If our match falls within the bold section, it's the definition itself
            offset = len(line) - len(stripped) + 2  # start of bold content
            if match_start_in_line >= offset and match_start_in_line < offset + len(bold_section):
                return True
    return False


def _is_in_quotes(line: str, match_start: int, match_end: int) -> bool:
    """Check if a match is inside double quotes (e.g., creatures with "burrow" in their speed)."""
    # Find all quoted regions in the line
    in_quote = False
    quote_start = -1
    for i, ch in enumerate(line):
        if ch == '"' or ch == '\u201c' or ch == '\u201d':
            if not in_quote:
                in_quote = True
                quote_start = i
            else:
                # End of quoted region
                if match_start > quote_start and match_end <= i:
                    return True
                in_quote = False
    return False


def _is_in_table_header(line: str) -> bool:
    """Check if a line is a table header or separator."""
    stripped = line.strip()
    if stripped.startswith('|'):
        # Check if it's a separator row
        if re.match(r'^\|[\s\-:|]+\|$', stripped):
            return True
    return False


def link_terms(content: str, tiers: set[str], review_mode: bool = False) -> tuple[str, dict]:
    """Process content and add links for terms in the specified tiers.

    Returns (new_content, stats_dict).
    """
    lines = content.split('\n')
    stats = {"linked": 0, "skipped_existing": 0, "skipped_header": 0,
             "skipped_bold_def": 0, "skipped_table": 0, "review": []}

    new_lines = []
    for line_num, line in enumerate(lines, 1):
        # Skip headers entirely
        if _is_in_header(line):
            new_lines.append(line)
            continue

        # Skip table separators
        if _is_in_table_header(line):
            new_lines.append(line)
            continue

        new_line = _link_line(line, line_num, tiers, stats, review_mode)
        new_lines.append(new_line)

    return '\n'.join(new_lines), stats


def _link_line(line: str, line_num: int, tiers: set[str], stats: dict,
               review_mode: bool) -> str:
    """Process a single line, adding links for matching terms."""
    # Process terms longest-first to avoid partial replacement issues
    for term in TERMS:
        if term.tier not in tiers:
            continue

        pattern = _build_pattern(term)

        # Find all matches in the current state of the line, process right-to-left
        # to preserve positions
        matches = list(pattern.finditer(line))
        if not matches:
            continue

        for match in reversed(matches):
            start, end = match.start(), match.end()
            matched_text = match.group(0)

            # Skip if inside existing link
            if _is_inside_link(line, start, end):
                stats["skipped_existing"] += 1
                continue

            # Skip if in bold definition
            if _is_in_bold_def(line, start):
                stats["skipped_bold_def"] += 1
                continue

            # Skip if inside quotes (e.g., "burrow" in definition text)
            if _is_in_quotes(line, start, end):
                stats["skipped_existing"] += 1
                continue

            # Build the link
            link = f"[{matched_text}]({term.uri})"

            if review_mode and term.tier == "dangerous":
                context_start = max(0, start - 40)
                context_end = min(len(line), end + 40)
                context = line[context_start:context_end]
                stats["review"].append({
                    "line": line_num,
                    "term": term.display,
                    "uri": term.uri,
                    "tier": term.tier,
                    "context": context,
                    "matched": matched_text,
                })
                continue  # Don't apply dangerous links in review mode

            # Apply the link
            line = line[:start] + link + line[end:]
            stats["linked"] += 1

    return line


# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------

def main():
    args = sys.argv[1:]

    dry_run = "--dry-run" in args
    review_mode = "--review" in args
    args = [a for a in args if not a.startswith("--")]

    if not args:
        print("Usage: autolink.py <file.md> [--dry-run] [--review]", file=sys.stderr)
        print("", file=sys.stderr)
        print("Tiers applied:", file=sys.stderr)
        print("  safe + contextual: always applied", file=sys.stderr)
        print("  dangerous: skipped (use --review to see candidates)", file=sys.stderr)
        sys.exit(1)

    filepath = Path(args[0])
    content = filepath.read_text()

    # Always apply safe + contextual tiers; include dangerous for review scanning
    tiers = {"safe", "contextual"}
    if review_mode:
        tiers.add("dangerous")

    new_content, stats = link_terms(content, tiers, review_mode=review_mode)

    # Print stats
    print(f"Links added:           {stats['linked']}", file=sys.stderr)
    print(f"Skipped (in link):     {stats['skipped_existing']}", file=sys.stderr)
    print(f"Skipped (header):      {stats['skipped_header'] if 'skipped_header' in stats else 'N/A'}", file=sys.stderr)
    print(f"Skipped (bold def):    {stats['skipped_bold_def']}", file=sys.stderr)
    print(f"Skipped (table):       {stats['skipped_table']}", file=sys.stderr)

    if review_mode and stats["review"]:
        print(f"\n--- DANGEROUS TIER REVIEW ({len(stats['review'])} candidates) ---",
              file=sys.stderr)
        for r in stats["review"]:
            print(f"  L{r['line']:5d} | {r['term']:25s} | {r['tier']:10s} | ...{r['context']}...",
                  file=sys.stderr)

    if dry_run:
        print("\n[DRY RUN] No changes written.", file=sys.stderr)
    else:
        filepath.write_text(new_content)
        print(f"\nWrote {filepath}", file=sys.stderr)


if __name__ == "__main__":
    main()
