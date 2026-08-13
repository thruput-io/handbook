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

from __future__ import annotations

from dataclasses import asdict, dataclass
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
    r"^\|\s*\*\*[^*]+\*\*<br>_(?P<title>[^_]+)_\s*\|\s*(?P<directives>[^|]+?)\s*\|\s*\[[^\]]+\]\((?P<url>[^)]+)\)\s*\|"
)
URL_BOOK_ID_RE = re.compile(r"/(?:tree|blob)/main/(?P<id>[^/]+)/")


@dataclass(frozen=True)
class RulesetEntry:
    id: str
    title: str
    author: str | None
    focus: str | None
    when_to_use: str
    review_checklist: str | None
    tree_url: str
    canonical_url: str

    def __post_init__(self) -> None:
        if not self.id or not self.id.strip():
            raise ValueError("RulesetEntry must have a non-empty id")
        if not self.title or not self.title.strip():
            raise ValueError(f"RulesetEntry '{self.id}' must have a non-empty title")
        if not self.when_to_use or not self.when_to_use.strip():
            raise ValueError(f"RulesetEntry '{self.id}' must have a non-empty when_to_use")
        if not self.tree_url or not self.tree_url.strip():
            raise ValueError(f"RulesetEntry '{self.id}' must have a non-empty tree_url")
        if not self.canonical_url or not self.canonical_url.strip():
            raise ValueError(f"RulesetEntry '{self.id}' must have a non-empty canonical_url")

    def to_dict(self) -> dict[str, str | None]:
        return asdict(self)


def strip_emoji_prefix(text: str) -> str:
    return re.sub(r"^[^\w]+\s*", "", text).strip()


def parse_curated_index(path: str) -> list[RulesetEntry]:
    with open(path, "r", encoding="utf-8") as f:
        lines = f.read().splitlines()

    parsed_raw: list[dict[str, str | None]] = []
    current_focus: str | None = None
    pending: dict[str, str | None] | None = None

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
            parsed_raw.append(pending)
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

    # Matrix: map book id and/or title -> directives
    directives_by_id: dict[str, str] = {}
    directives_by_title: dict[str, str] = {}

    for raw in lines:
        row = MATRIX_ROW_RE.match(raw)
        if row:
            directives = row.group("directives").strip()
            title = row.group("title").strip()
            url = row.group("url").strip()
            directives_by_title[title] = directives

            url_match = URL_BOOK_ID_RE.search(url)
            if url_match:
                directives_by_id[url_match.group("id").strip()] = directives

    entries: list[RulesetEntry] = []
    for item in parsed_raw:
        item_id = item["id"]
        item_title = item["title"]

        checklist: str | None = None
        if item_id and item_id in directives_by_id:
            checklist = directives_by_id[item_id]
        elif item_title and item_title in directives_by_title:
            checklist = directives_by_title[item_title]

        entry = RulesetEntry(
            id=item["id"] or "",
            title=item["title"] or "",
            author=item["author"],
            focus=item["focus"],
            when_to_use=item["when_to_use"] or "",
            review_checklist=checklist,
            tree_url=item["tree_url"] or "",
            canonical_url=item["canonical_url"] or "",
        )
        entries.append(entry)

    return entries


def find_unindexed_submodule_entries(entries: list[RulesetEntry]) -> list[str]:
    if not os.path.isdir(books_dir):
        raise FileNotFoundError(f"Submodule directory not found or not a directory: {books_dir}")

    indexed_ids = {e.id for e in entries}
    submodule_ids: list[str] = []
    for name in sorted(os.listdir(books_dir)):
        path = os.path.join(books_dir, name)
        if not os.path.isdir(path) or name.startswith(".") or name.startswith("_") or name == "docs":
            continue
        submodule_ids.append(name)

    if not submodule_ids:
        raise ValueError(f"Submodule directory contains no rulesets: {books_dir}")

    return [book_id for book_id in submodule_ids if book_id not in indexed_ids]


def main() -> int:
    if not os.path.exists(curated_index_path):
        print(f"Curated index not found: {curated_index_path}", file=sys.stderr)
        return 1

    entries = parse_curated_index(curated_index_path)

    try:
        unindexed = find_unindexed_submodule_entries(entries)
    except (FileNotFoundError, ValueError) as err:
        print(f"Submodule error: {err}", file=sys.stderr)
        return 1

    if unindexed:
        print("Rulesets present in the submodule but not referenced in agent-rules-books-INDEX.md:", file=sys.stderr)
        for book_id in unindexed:
            print(f"  - {book_id}", file=sys.stderr)
        return 1

    serialized = [entry.to_dict() for entry in entries]
    with open(json_output_path, "w", encoding="utf-8") as f:
        json.dump(serialized, f, indent=2)

    return 0


if __name__ == "__main__":
    sys.exit(main())
