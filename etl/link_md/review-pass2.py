#!/usr/bin/env python3
"""
Second-pass review: remove scc: links that survived the first pass but
are still incorrect -- the display text is used in its common English
meaning rather than referencing the game rule.

Operates on git-diff added lines only, identifying patterns that indicate
prose/idiom/narrative usage rather than game-mechanic references.
"""

import re
import json


def load_file(path: str) -> list[str]:
    with open(path, "r", encoding="utf-8") as f:
        return f.readlines()


def write_file(path: str, lines: list[str]):
    with open(path, "w", encoding="utf-8") as f:
        f.writelines(lines)


LINK_RE = re.compile(r'\[([^\]]*)\]\(scc:([^)]+)\)')


def should_remove(line: str, display: str, scc_key: str, m_start: int, m_end: int) -> str | None:
    """Return a reason string if this link should be removed, None to keep."""
    dl = display.lower()
    slug = scc_key.split(":")[-1].replace("-", " ")
    scc_type = scc_key.split(":")[1].split(".")[0] if ":" in scc_key else ""
    prefix = line[:m_start].lower()
    suffix = line[m_end:m_end + 60].lower()

    # ---------------------------------------------------------------
    # "one" -- the number/pronoun, not the Elementalist feature
    # ---------------------------------------------------------------
    if slug == "one":
        return "one: always the number/pronoun"

    # ---------------------------------------------------------------
    # "crawl" in "hex crawl" -- game genre, not movement
    # ---------------------------------------------------------------
    if slug == "crawl" and re.search(r'\bhex\s+$', prefix):
        return "crawl: hex crawl is a game genre"

    # ---------------------------------------------------------------
    # "raider" in "*Raiders of the Lost Ark*"
    # ---------------------------------------------------------------
    if slug == "raider" and ("lost ark" in suffix or "lost ark" in prefix[-30:]):
        return "raider: movie title"
    if slug == "raider" and re.search(r'\*$', prefix):
        return "raider: inside italics (movie/book title)"

    # ---------------------------------------------------------------
    # "fly" in "on the fly" idiom
    # ---------------------------------------------------------------
    if slug == "fly" and re.search(r'\bon\s+the\s+$', prefix):
        return "fly: 'on the fly' idiom"

    # ---------------------------------------------------------------
    # "walk" -- almost always prose verb, not the Walk movement
    # ---------------------------------------------------------------
    if slug == "walk":
        # Keep only in mechanical tables or "Walk speed" patterns
        if re.search(r'^\s*(speed|\d|movement|mode)', suffix):
            return None  # mechanical
        if re.search(r'\|\s*$', prefix) and re.search(r'^\s*\|', suffix):
            return None  # table cell
        return "walk: prose verb, not Walk movement"

    # ---------------------------------------------------------------
    # "jump" -- idiom/prose uses
    # ---------------------------------------------------------------
    if slug == "jump":
        # "jump into" (idiom), "jump right into" (idiom)
        if re.search(r'^\s+(into|right|in\b)', suffix):
            return "jump: idiomatic 'jump into'"
        # Keep in tables and mechanical contexts
        if re.search(r'\|\s*$', prefix) and re.search(r'^\s*\|', suffix):
            return None
        if re.search(r'\b(can|can\'t|cannot|to|must|and|or)\s+$', prefix):
            return None
        if re.search(r'^\s*(speed|movement|distance|squares?|[\.,;]|\d)', suffix):
            return None

    # ---------------------------------------------------------------
    # "advance" -- prose verb meaning "progress/further/move forward"
    # ---------------------------------------------------------------
    if slug == "advance":
        # Keep: "the Advance move action", "taking the Advance", "use the Advance"
        if display[0].isupper() and re.search(r'\b(the|take|taking|use)\s+$', prefix):
            return None
        # Keep: "Advance move action" or "Advance or Disengage" (game mechanic lists)
        if display[0].isupper() and re.search(r'^\s*(move\s+action|or\s+\[)', suffix):
            return None
        # Keep: "Advance" in tables
        if display[0].isupper() and re.search(r'\|\s*$', prefix):
            return None
        # Keep: "can advance" in movement context (but NOT "can advance the story")
        if re.search(r'\bcan\s+$', prefix) and not re.search(r'^\s+(the|their|his|her|your|its)', suffix):
            return None
        # Remove: "advance in level/faith/their tradition"
        level_patterns = [
            r'^\s+(from|in|to)\s+(one\s+)?(level|their|your|his|her)',
            r'^\s+at\s+(double|half|the)',
            r'^\s+using\s+the\s+standard',
        ]
        for pat in level_patterns:
            if re.search(pat, suffix):
                return "advance: means 'progress', not the move action"
        # "heroes advance" = level up
        if re.search(r'\bheroes\s+$', prefix):
            return "advance: 'heroes advance' = level up"
        # "advance the story/goals/interests/plans/theories"
        if re.search(r'^\s+(the\s+story|the\s+faction|their|his|her|your|its)', suffix):
            return "advance: means 'further/progress'"
        # "in advance" = beforehand
        if re.search(r'\bin\s+$', prefix):
            return "advance: 'in advance' = beforehand"
        # "advance his theories" etc.
        if re.search(r'^\s+\w+\s+(theories|plans|goals|interests|cause)', suffix):
            return "advance: means 'further/progress'"

    # ---------------------------------------------------------------
    # "charge" -- "their charge" (ward), "charges" (uses), "in charge"
    # ---------------------------------------------------------------
    if slug == "charge":
        # "charges" meaning uses/ammunition or legal charges
        if dl == "charges":
            return "charge: 'charges' = item uses/legal, not the Charge action"
        # "their/the charge" meaning person under protection
        # But NOT "part of your/the charge" or "path of your charge" (= Charge movement)
        if re.search(r'\b(their|its)\s+$', prefix) and not re.search(r'\bpart\s+of\s+$', prefix[-20:]):
            if not re.search(r'^\s*(action|keyword|attack|movement|main)', suffix):
                return "charge: means 'person under protection'"
        # "returned the charge" in battle narrative
        if re.search(r'\breturned\s+the\s+$', prefix):
            return "charge: 'returned the charge' = narrative"
        # "get their charge to" = person under protection
        if re.search(r'\bget\s+their\s+$', prefix):
            return "charge: means 'person under protection'"
        # "protect their charge" = person under protection
        if re.search(r'\bprotect\s+their\s+$', prefix):
            return "charge: means 'person under protection'"

    # ---------------------------------------------------------------
    # "defend" -- prose verb "protect/guard"
    # ---------------------------------------------------------------
    if slug == "defend":
        # Keep: "the Defend action", "use Defend", in tables
        if display[0].isupper() and re.search(r'\bthe\s+$', prefix):
            return None
        if re.search(r'\buse\s+$', prefix):
            return None
        if re.search(r'^\s*(action|maneuver|\|)', suffix):
            return None
        # "Defend" in a list of ability names (parenthetical)
        if display[0].isupper() and re.search(r'[\(,]\s*$', prefix):
            return None
        # Remove: prose "defend and protect", "defend Hell", "defend the [place]"
        if re.search(r'^\s+(and\s+(protect|hold)|hell\b|the\s+(city|town|kingdom|realm|natural|settlement|dwarf))', suffix):
            return "defend: prose verb meaning 'protect'"
        # "defend your allies" / "defend your allies" in class descriptions = prose
        if re.search(r'^\s+your\s+allies\b', suffix):
            return "defend: 'defend your allies' = prose description"
        # "defend yourself" = prose in narrative (not the Defend action)
        if re.search(r'^\s+yourself\b', suffix) and not re.search(r'\b(action|maneuver)\b', suffix[:40]):
            return "defend: 'defend yourself' = prose"
        # "swore to defend" = narrative
        if re.search(r'\bswore\s+to\s+$', prefix):
            return "defend: narrative prose"
        # "from which to defend" = narrative
        if re.search(r'\bto\s+$', prefix) and display[0].islower():
            return "defend: prose infinitive"
        # "indemnify and hold" = legal text
        if re.search(r'\bindemnify\b', suffix[:30]):
            return "defend: legal text"

    # ---------------------------------------------------------------
    # "focus" -- prose verb/noun meaning "emphasis/concentrate"
    # ---------------------------------------------------------------
    if slug == "focus":
        # PROSE PATTERNS (check first -- these override resource patterns)
        # "focus on [topic]" = emphasis
        if re.search(r'^\s+on\s', suffix):
            return "focus: 'focus on' = emphasis, not the resource"
        # "the focus of" = emphasis
        if re.search(r'\bthe\s+$', prefix) and re.search(r'^\s+of\b', suffix):
            return "focus: 'the focus of' = emphasis"
        # "maintain your focus" = concentration
        if re.search(r'\bmaintain\s+(your|their)\s+$', prefix):
            return "focus: 'maintain focus' = concentration"
        # "turned their focus" = prose
        if re.search(r'\b(turned|turn)\s+(their|his|her)\s+$', prefix):
            return "focus: 'turned focus' = prose"
        # "focus and precision" = prose (general mental quality)
        if re.search(r'^\s+and\s+(precision|determination|clarity\s+of\s+mind)', suffix):
            return "focus: prose noun"

        # RESOURCE PATTERNS (keep)
        if re.search(r'\b(gain|spend|lose|earn|starting|extra|maximum|current|bonus|amount\s+of)\s+$', prefix):
            return None
        if re.search(r'^\s*(points?|score|pool|equal|increases?|decreases?|drops?|reaches?|[\.,;:]|\d)', suffix):
            return None
        # "Focus" capitalized in feature tables/lists
        if display[0].isupper() and (re.search(r'\|\s*$', prefix) or re.search(r'^\s*[\|,]', suffix)):
            return None
        # "focus" in "waste any focus", "costs focus", "that costs focus"
        if re.search(r'\b(any|costs?|were?|it)\s+$', prefix):
            return None
        # "your focus" in resource context (not followed by "on/of/in")
        if re.search(r'\byour\s+$', prefix) and not re.search(r'^\s+(on|of|in)\b', suffix):
            return None
        # "Heroic Resource called focus"
        if re.search(r'\bcalled\s+$', prefix):
            return None

    # ---------------------------------------------------------------
    # "medium" -- weapon size, not the Medium complication
    # ---------------------------------------------------------------
    if slug == "medium" and scc_key.endswith("complication:medium"):
        # "Medium weapons", "Medium armor", "Light, medium"
        if re.search(r'^\s*(weapon|armor|shield|melee|ranged)', suffix):
            return "medium: weapon/armor size category, not the complication"
        # In kit tables: "Medium" in the armor/weapon column
        if re.search(r'\|\s*$', prefix) and re.search(r'^\s*\|', suffix):
            return "medium: weapon/armor size in table"
        # "Light, medium" or "medium, heavy"
        if re.search(r'\b(light|heavy)[,\s]', prefix[-20:]) or re.search(r'^\s*[,/]\s*(light|heavy|bow|polearm|ensnaring)', suffix):
            return "medium: weapon size list"
        # "medium weapon" or "Medium weapon"
        return "medium: weapon/armor size category"

    # ---------------------------------------------------------------
    # "essence" in "of the essence" idiom
    # ---------------------------------------------------------------
    if slug == "essence":
        if re.search(r'\bof\s+the\s+$', prefix):
            return "essence: 'of the essence' idiom"

    # ---------------------------------------------------------------
    # "insight" as prose noun = understanding
    # ---------------------------------------------------------------
    if slug == "insight":
        # Keep: in Shadow class section, "Insight" as feature name, resource refs
        if display[0].isupper():
            return None
        # "his/her/their insight" in narrative
        if re.search(r'\b(his|her|their|king\'?s?)\s+$', prefix):
            return "insight: prose noun meaning 'understanding'"
        # "your insight into" -- could be game or prose. Keep in class sections.
        # Check for nearby shadow/class refs
        if "shadow" in line.lower()[:m_start] or "scc:" in line[:m_start]:
            return None  # likely in mechanical context
        if re.search(r'^\s+into\b', suffix) and "shadow" not in prefix[-100:]:
            return "insight: 'insight into' = understanding"

    # ---------------------------------------------------------------
    # "order" as prose noun
    # ---------------------------------------------------------------
    if slug == "order":
        # Keep: capitalized in tables/feature lists
        if display[0].isupper() and re.search(r'(\|\s*$|^\s*[\|,])', prefix + '|' + suffix):
            return None
        # Keep: "Order Features", "Order Abilities", "Order Ability"
        if display[0].isupper() and re.search(r'^\s*(feature|abilit)', suffix):
            return None
        # Remove: "Order dies" (societal), "Order of [Proper Name]"
        if re.search(r'^\s+dies\b', suffix):
            return "order: 'Order dies' = societal order"
        if re.search(r'^\s+of\s+[A-Z]', line[m_end:m_end+30]):
            return "order: 'Order of [Name]' = organization"

    # ---------------------------------------------------------------
    # "ride" idioms
    # ---------------------------------------------------------------
    if slug == "ride":
        if re.search(r'\bfor\s+the\s+$', prefix):
            return "ride: 'along for the ride' idiom"
        if re.search(r'\bhitch\s+a\s+$', prefix):
            return "ride: 'hitch a ride' idiom"
        # Keep: "Ride" in tables, skill references, mounted combat
        if display[0].isupper():
            return None
        if re.search(r'\b(can|to|and|or)\s+$', prefix) and re.search(r'^\s*(another|a\s|into|the|your)', suffix):
            return None  # mechanical "ride another creature"

    # ---------------------------------------------------------------
    # "shadow" -- Queen of Shadows, literal shadows
    # ---------------------------------------------------------------
    if slug == "shadow" and scc_type == "class":
        # "Queen of Shadows"
        if re.search(r'\bqueen\s+of\s+$', prefix):
            return "shadow: 'Queen of Shadows' = proper name"
        # "blend in with the shadows"
        if re.search(r'\bwith\s+the\s+$', prefix) and dl == "shadows":
            return "shadow: literal shadows"

    # ---------------------------------------------------------------
    # "noble" as adjective
    # ---------------------------------------------------------------
    if slug == "noble":
        if re.search(r'^\s+title\b', suffix):
            return "noble: 'noble title' = adjective"

    # ---------------------------------------------------------------
    # "talent" as prose noun = aptitude
    # ---------------------------------------------------------------
    if slug == "talent" and scc_type == "class":
        if dl in ("talent", "talents"):
            # "talent tradition" = game term (Talent class subclass). KEEP.
            if re.search(r'^\s+tradition\b', suffix):
                return None
            # "your talents to the surface" = aptitude
            if re.search(r'\btake\s+your\s+$', prefix):
                return "talent: prose 'take your talents'"
            # "talent for crafting" = aptitude
            if re.search(r'^\s+for\s+(crafting|making|building)', suffix):
                return "talent: 'talent for X' = aptitude"

    # ---------------------------------------------------------------
    # "tooth and claw" as prose idiom
    # ---------------------------------------------------------------
    if slug == "tooth and claw":
        # Keep only in feature tables
        if re.search(r'\|\s*$', prefix) or re.search(r'^\s*\|', suffix):
            return None
        # "law... tooth and claw" = prose idiom about nature
        if re.search(r'\blaw\b', prefix[-30:]):
            return "tooth and claw: prose idiom"
        # Check: is it in a class feature section?
        if display[0].isupper():
            return None
        return "tooth and claw: prose idiom"

    # ---------------------------------------------------------------
    # "stand fast" as prose exhortation
    # ---------------------------------------------------------------
    if slug == "stand fast":
        # Keep in tables
        if re.search(r'\|\s*$', prefix) or re.search(r'^\s*[\|!]', suffix):
            return None
        # "stand fast, and do not yield" = prose
        if re.search(r'^\s*[,.]', suffix):
            return "stand fast: prose exhortation"

    # ---------------------------------------------------------------
    # "criminal" as common noun (not Career reference)
    # ---------------------------------------------------------------
    if slug == "criminal" and scc_type == "career":
        # Keep: table entries, "Criminal Underworld" skill name, capitalized career refs
        if display[0].isupper() and re.search(r'^\s*(underworld|gang)', suffix):
            return None
        if re.search(r'\|\s*$', prefix):
            return None
        # "Criminals run from" = common noun
        if dl == "criminals" and not re.search(r'\|\s*$', prefix):
            return "criminal: common noun, not the Career"

    # ---------------------------------------------------------------
    # "farmer" as common noun
    # ---------------------------------------------------------------
    if slug == "farmer" and scc_type == "career":
        if display[0].isupper() and re.search(r'\|\s*$', prefix):
            return None  # table
        if dl == "farmers" and not re.search(r'\|\s*$', prefix):
            return "farmer: common noun, not the Career"

    # ---------------------------------------------------------------
    # "enchantment" in "Tower of Enchantment" = proper name
    # ---------------------------------------------------------------
    if slug == "enchantment":
        if re.search(r'\btower\s+of\s+$', prefix):
            return "enchantment: 'Tower of Enchantment' = proper place name"

    # ---------------------------------------------------------------
    # "vision" as prose noun (eyesight)
    # ---------------------------------------------------------------
    if slug == "vision":
        # "adjust your vision" -- ancestry feature about eyesight
        if re.search(r'\b(adjust|your)\s+$', prefix) and "talent" not in prefix[-80:].lower():
            if re.search(r'^\s+(to|is|this|adjusted)', suffix):
                return "vision: prose noun meaning 'eyesight'"

    return None


def process(md_path: str, dry_run: bool = False):
    lines = load_file(md_path)
    removed_count = 0
    removed_by_reason = {}

    output = []
    for line_idx, line in enumerate(lines):
        new_line = line
        offset = 0

        for m in LINK_RE.finditer(line):
            display = m.group(1)
            scc_key = m.group(2)
            adj_start = m.start() + offset
            adj_end = m.end() + offset

            reason = should_remove(new_line, display, scc_key,
                                   adj_start, adj_end)
            if reason:
                old = f"[{display}](scc:{scc_key})"
                new_line = new_line[:adj_start] + display + new_line[adj_end:]
                offset += len(display) - len(old)
                removed_count += 1
                cat = reason.split(":")[0]
                removed_by_reason[cat] = removed_by_reason.get(cat, 0) + 1

        output.append(new_line)

    print(f"\nLinks removed: {removed_count}")
    for cat, count in sorted(removed_by_reason.items(), key=lambda x: -x[1]):
        print(f"  {count:4d}  {cat}")

    if not dry_run and removed_count > 0:
        write_file(md_path, output)
        print(f"\nFile updated: {md_path}")
    elif dry_run:
        print("\n(Dry run)")


if __name__ == "__main__":
    import argparse
    p = argparse.ArgumentParser()
    p.add_argument("markdown_file")
    p.add_argument("--dry-run", action="store_true")
    process(p.parse_args().markdown_file, p.parse_args().dry_run)
