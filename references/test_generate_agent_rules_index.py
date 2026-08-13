"""Tests for generate_agent_rules_index.py.

Verifies that:
1. Curated index parsing generates strongly typed RulesetEntry dataclasses.
2. The `local_path` field is omitted per PR #11 specifications (addressing rulesets by URL only).
3. `agent-rules-books-search-index.json` is valid and contains no `local_path` keys.
4. Fail-fast validation prevents incomplete/null required fields in RulesetEntry.
5. All rulesets in matrix (including designing-data-intensive-applications) receive non-null review_checklist values.
6. `find_unindexed_submodule_entries` fails if the submodule directory is missing or empty.
7. `main()` executes cleanly and returns 0 when requirements are satisfied.
"""

from __future__ import annotations

import json
import os
import tempfile
import unittest

from references.generate_agent_rules_index import (
    RulesetEntry,
    find_unindexed_submodule_entries,
    main,
    parse_curated_index,
    strip_emoji_prefix,
)


class TestGenerateAgentRulesIndex(unittest.TestCase):

    def test_strip_emoji_prefix(self) -> None:
        self.assertEqual(strip_emoji_prefix("📚 Architecture & Design"), "Architecture & Design")
        self.assertEqual(strip_emoji_prefix("Clean Code"), "Clean Code")

    def test_ruleset_entry_fail_fast_validation(self) -> None:
        with self.assertRaises(ValueError):
            RulesetEntry(
                id="test-id",
                title="Test Title",
                author="Author",
                focus="Focus",
                when_to_use="When to use",
                review_checklist=None,
                tree_url="https://github.com/tree",
                canonical_url="",  # Empty canonical_url must fail fast
            )

        with self.assertRaises(ValueError):
            RulesetEntry(
                id="test-id",
                title="Test Title",
                author="Author",
                focus="Focus",
                when_to_use="   ",  # Blank when_to_use must fail fast
                review_checklist=None,
                tree_url="https://github.com/tree",
                canonical_url="https://github.com/canonical",
            )

    def test_parse_curated_index_returns_ruleset_entries(self) -> None:
        script_dir = os.path.dirname(os.path.abspath(__file__))
        curated_index_path = os.path.join(script_dir, "agent-rules-books-INDEX.md")
        self.assertTrue(os.path.exists(curated_index_path), f"File not found: {curated_index_path}")

        entries = parse_curated_index(curated_index_path)
        self.assertGreater(len(entries), 0, "Parsed entries list should not be empty")

        for entry in entries:
            self.assertIsInstance(entry, RulesetEntry)
            self.assertFalse(hasattr(entry, "local_path"))
            entry_dict = entry.to_dict()
            self.assertNotIn("local_path", entry_dict)
            self.assertTrue(entry.id)
            self.assertTrue(entry.title)
            self.assertTrue(entry.when_to_use)
            self.assertTrue(entry.tree_url.startswith("https://"))
            self.assertTrue(entry.canonical_url.startswith("https://"))

    def test_ddia_review_checklist_populated(self) -> None:
        script_dir = os.path.dirname(os.path.abspath(__file__))
        curated_index_path = os.path.join(script_dir, "agent-rules-books-INDEX.md")
        entries = parse_curated_index(curated_index_path)

        ddia = next((e for e in entries if e.id == "designing-data-intensive-applications"), None)
        self.assertIsNotNone(ddia, "designing-data-intensive-applications should be present in index")
        self.assertIsNotNone(
            ddia.review_checklist,
            "designing-data-intensive-applications review_checklist must not be null",
        )
        self.assertIn("data corruption", ddia.review_checklist)

    def test_parse_curated_index_sample(self) -> None:
        sample_md = """### 📐 Sample Category

* **[sample-book (Sample Author)](https://github.com/example/repo/tree/main/sample-book)**
  *When to use sample book.*
  [Canonical Full Ruleset](https://github.com/example/repo/blob/main/sample-book/sample-book.md)

| Category | Selection matrix | Link |
| --- | --- | --- |
| **Sample Category**<br>_sample-book_ | Do sample checklist. | [Link](https://github.com/example/repo/blob/main/sample-book/sample-book.md) |
"""
        with tempfile.NamedTemporaryFile("w+", encoding="utf-8", delete=False) as f:
            f.write(sample_md)
            temp_path = f.name

        try:
            entries = parse_curated_index(temp_path)
            self.assertEqual(len(entries), 1)
            entry = entries[0]
            self.assertEqual(entry.id, "sample-book")
            self.assertEqual(entry.title, "sample-book")
            self.assertEqual(entry.author, "Sample Author")
            self.assertEqual(entry.focus, "Sample Category")
            self.assertEqual(entry.when_to_use, "When to use sample book.")
            self.assertEqual(
                entry.tree_url,
                "https://github.com/example/repo/tree/main/sample-book",
            )
            self.assertEqual(
                entry.canonical_url,
                "https://github.com/example/repo/blob/main/sample-book/sample-book.md",
            )
            self.assertEqual(entry.review_checklist, "Do sample checklist.")
            self.assertNotIn("local_path", entry.to_dict())
        finally:
            os.remove(temp_path)

    def test_generated_json_file(self) -> None:
        script_dir = os.path.dirname(os.path.abspath(__file__))
        json_path = os.path.join(script_dir, "agent-rules-books-search-index.json")
        self.assertTrue(os.path.exists(json_path), f"JSON index not found: {json_path}")

        with open(json_path, "r", encoding="utf-8") as f:
            data = json.load(f)

        self.assertIsInstance(data, list)
        self.assertGreater(len(data), 0)

        ddia_item = next((item for item in data if item.get("id") == "designing-data-intensive-applications"), None)
        self.assertIsNotNone(ddia_item)
        self.assertIsNotNone(ddia_item.get("review_checklist"))

        for item in data:
            self.assertNotIn(
                "local_path",
                item,
                "local_path key must not exist in emitted JSON index per PR #11",
            )
            self.assertIn("id", item)
            self.assertIn("canonical_url", item)

    def test_find_unindexed_submodule_entries_missing_directory(self) -> None:
        sample_entries = [
            RulesetEntry(
                id="book-a",
                title="Title A",
                author=None,
                focus=None,
                when_to_use="When to use",
                review_checklist=None,
                tree_url="https://github.com/tree",
                canonical_url="https://github.com/canonical",
            )
        ]
        non_existent_path = os.path.join(tempfile.gettempdir(), "non_existent_submodule_dir_12345")
        original_dir = set_module_books_dir(non_existent_path)
        try:
            with self.assertRaises(FileNotFoundError):
                find_unindexed_submodule_entries(sample_entries)
        finally:
            set_module_books_dir(original_dir)

    def test_find_unindexed_submodule_entries_empty_directory(self) -> None:
        sample_entries = [
            RulesetEntry(
                id="book-a",
                title="Title A",
                author=None,
                focus=None,
                when_to_use="When to use",
                review_checklist=None,
                tree_url="https://github.com/tree",
                canonical_url="https://github.com/canonical",
            )
        ]
        with tempfile.TemporaryDirectory() as tmp_dir:
            original_dir = set_module_books_dir(tmp_dir)
            try:
                with self.assertRaises(ValueError):
                    find_unindexed_submodule_entries(sample_entries)
            finally:
                set_module_books_dir(original_dir)

    def test_find_unindexed_submodule_entries_unindexed_ruleset(self) -> None:
        sample_entries = [
            RulesetEntry(
                id="book-a",
                title="Title A",
                author=None,
                focus=None,
                when_to_use="When to use",
                review_checklist=None,
                tree_url="https://github.com/tree",
                canonical_url="https://github.com/canonical",
            )
        ]
        with tempfile.TemporaryDirectory() as tmp_dir:
            os.makedirs(os.path.join(tmp_dir, "book-a"))
            os.makedirs(os.path.join(tmp_dir, "book-b"))
            original_dir = set_module_books_dir(tmp_dir)
            try:
                unindexed = find_unindexed_submodule_entries(sample_entries)
                self.assertEqual(unindexed, ["book-b"])
            finally:
                set_module_books_dir(original_dir)

    def test_main_execution(self) -> None:
        exit_code = main()
        self.assertEqual(exit_code, 0, "main() should execute cleanly and return 0")


def set_module_books_dir(new_path: str) -> str:
    import references.generate_agent_rules_index as mod
    old = mod.books_dir
    mod.books_dir = new_path
    return old


if __name__ == "__main__":
    unittest.main()
