"""Build a search index that helps an agent pick the right ruleset for a review.

Source of truth is the curated agent-rules-books-INDEX.md. This script parses
it and emits a JSON index with, per ruleset: title, author, focus category,
when-to-use blurb, review checklist (when present in the selection matrix),
and canonical URL.

Rulesets are addressed only by URL. A submodule-relative path is deliberately
not emitted: the index is consumed outside this repository (for example bundled
into the pr-review skill), where the agent-rules-books submodule is absent, and
a path that resolves only here reads as available when it is not.
"""

import json
import os
import re
import sys

script_dir = os.path.dirname(os.path.abspath(__file__))
books_dir_name = "agent-rules-books"
books_dir = os.path.join(script_dir, books_dir_name)
curated_index_path = os.path.join(script_dir, "agent-rules-books-INDEX.md")
json_output_path = os.path.join(script_dir, "agent-rules-books-search-index.json")

BOOK_LINK_RE = re.compile(
    r"^\*\s+\*\*\[(?P<label>[^\]]+)\]\((?P<tree_url>https://github\.com/[^)]+/tree/main/(?P<id>[^)]+))\)\*\*"
)
CANONICAL_RE = re.compile(r"\[Canonical Full Ruleset\]\((?P<url>[^)]+)\)")
FOCUS_HEADING_RE = re.compile(r"^###\s+(?P<focus>.+?)\s*$")
LABEL_SPLIT_RE = re.compile(r"^(?P<title>.+?)\s*\((?P<author>[^)]+)\)\s*$")
MATRIX_ROW_RE = re.compile(
    r"^\|\s*\*\*[^*]+\*\*<br>_(?P<title>[^_]+)_\s*\|\s*(?P<directives>[^|]+?)\s*\|"
)

def strip_emoji_prefix(text: str) -> str:
    return re.sub(r"^[^\w]+\s*", "", text).strip()

def parse_curated_index(path: str) -> list[dict]:
    with open(path, "r", encoding="utf-8") as f:
        lines = f.read().splitlines()

    entries: list[dict] = []
    current_focus: str | None = None
    pending: dict | None = None

    for raw in lines:
        line = raw.rstrip()

        heading = FOCUS_HEADING_RE.match(line)
        if heading:
            current_focus = strip_emoji_prefix(heading.group("focus"))
            pending = None
            continue

        book = BOOK_LINK_RE.match(line.lstrip())
        if book:
            label = book.group("label").strip()
            m = LABEL_SPLIT_RE.match(label)
            title = m.group("title").strip() if m else label
            author = m.group("author").strip() if m else None
            pending = {
                "id": book.group("id").strip(),
                "title": title,
                "author": author,
                "focus": current_focus,
                "when_to_use": None,
                "review_checklist": None,
                "tree_url": book.group("tree_url").strip(),
                "canonical_url": None,
            }
            entries.append(pending)
            continue

        if pending is not None:
            stripped = line.strip()
            if pending["when_to_use"] is None and stripped.startswith("*") and stripped.endswith("*") and len(stripped) > 2:
                pending["when_to_use"] = stripped.strip("*").strip()
                continue
            canonical = CANONICAL_RE.search(stripped)
            if canonical:
                pending["canonical_url"] = canonical.group("url").strip()
                pending = None

    # Matrix: map book title -> directives, then merge into entries.
    directives_by_title: dict[str, str] = {}
    for raw in lines:
        row = MATRIX_ROW_RE.match(raw)
        if row:
            directives_by_title[row.group("title").strip()] = row.group("directives").strip()

    for entry in entries:
        if entry["title"] in directives_by_title:
            entry["review_checklist"] = directives_by_title[entry["title"]]

    return entries

def warn_missing_submodule_entries(entries: list[dict]) -> list[str]:
    indexed_ids = {e["id"] for e in entries}
    submodule_ids: list[str] = []
    if os.path.isdir(books_dir):
        for name in sorted(os.listdir(books_dir)):
            path = os.path.join(books_dir, name)
            if not os.path.isdir(path) or name.startswith(".") or name.startswith("_") or name == "docs":
                continue
            submodule_ids.append(name)
    return [book_id for book_id in submodule_ids if book_id not in indexed_ids]

def main() -> int:
    if not os.path.exists(curated_index_path):
        print(f"Curated index not found: {curated_index_path}", file=sys.stderr)
        return 1

    entries = parse_curated_index(curated_index_path)

    with open(json_output_path, "w", encoding="utf-8") as f:
        json.dump(entries, f, indent=2)

    missing = warn_missing_submodule_entries(entries)
    if missing:
        print("Rulesets present in the submodule but not referenced in agent-rules-books-INDEX.md:", file=sys.stderr)
        for book_id in missing:
            print(f"  - {book_id}", file=sys.stderr)
        return 1
    return 0

if __name__ == "__main__":
    sys.exit(main())
