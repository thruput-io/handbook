# PROBE SUBAGENT TEMPLATE

Instructions for a single review probe subagent, dispatched by [`CODE_REVIEW.md` step 3](./CODE_REVIEW.md#3-rule-evaluation). Copy the block below verbatim into the subagent prompt, substituting every `{{...}}` placeholder. One filled-in copy per probe — never batch two rules into one subagent.

---

You are running **one review probe** for a GitHub pull request review. Your entire job is to probe exactly one rule and return one ledger row. You do not review anything else, and you do not post anything to GitHub.

## Target

- Rule/principle: **{{RULE_HEADING}}**
- Rule source: {{RULE_SOURCE_URL}}
- PR: {{PR_URL}} (`{{OWNER}}/{{REPO}}` #{{NUMBER}})
- Head commit (`headRefOid`): `{{HEAD_REF_OID}}`
- Changed files:
{{CHANGED_FILES}}
- Local checkout: {{CHECKOUT_PATH_OR_NONE}}

## Method

1. Read the rule at its source URL. Probe the rule as written, not as you remember it.
2. Read the change set at `{{HEAD_REF_OID}}` — not the diff hunks alone. Hunks cannot show dead code, layering, primitive leakage, missing tests, or unrepresentable illegal states. Obtain:
   - every changed file relevant to this rule, in full;
   - the call sites of every changed public symbol you rely on;
   - the test files covering those files, including the case where none exist.

   Use the local checkout if one is given, otherwise fetch per file at `{{HEAD_REF_OID}}` as shown in [`gh-cheat-sheet.md § Read files at the head commit`](./gh-cheat-sheet.md#read-files-at-the-head-commit). If a fetch fails, record that in `examined` and return.
3. **If your rule asks whether this code needed to be written at all** — any rung of the [Simplicity ladder](./RULES.md#3-simplicity) — then searching is the probe, not optional background. Search the surface your rung names: this repository for an existing or extractable component; the language, runtime, and framework **at the version this project pins**; the package registry for this ecosystem; or existing tools and callable services. Name every search and every query in `examined`. A `clean` verdict means you searched and found nothing, and must say what you searched for — reading the diff and finding the code plausible is not a probe of these rules.
4. Decide a verdict: `violation`, `clean`, or `not-applicable`.
   - `clean` requires that you name what you checked that *would have exposed* a violation.
   - `not-applicable` requires a reason tied to this change set. "No findings" is not a reason.
   - If you could not obtain the context the probe needed, say so in `examined` and do **not** downgrade to `clean`.
5. Do not fabricate a finding to look thorough. Zero violations is an acceptable outcome.

## Return value

Return **only** this JSON object — no prose before or after:

```json
{
  "rule": "{{RULE_HEADING}}",
  "source_url": "{{RULE_SOURCE_URL}}",
  "examined": ["path/to/file.ts", "Symbol.method call sites", "path/to/file.test.ts (absent)"],
  "verdict": "violation | clean | not-applicable",
  "evidence": "For violation: file and line. For clean: what was checked that would have exposed a violation. For not-applicable: why the rule cannot apply to this change set.",
  "comments": [
    {
      "path": "src/foo.ts",
      "line": 42,
      "side": "RIGHT",
      "body": "What is wrong, briefly, citing the rule as an absolute URL: [{{RULE_HEADING}}]({{RULE_SOURCE_URL}})."
    }
  ]
}
```

- `comments` is `[]` unless the verdict is `violation`.
- Where the violation has no single line to blame — an existing component that replaces a whole module, a standard the change set as a whole does not follow — omit `path`, `line`, and `side`, and set `"pr_level": true`. The reviewer carries it in the review body instead of anchoring it to a line.
- `line` is the line number **in the file at `{{HEAD_REF_OID}}`**, not a diff hunk offset, and is a bare integer.
- `side` is `RIGHT` for added/modified lines, `LEFT` for removed lines.
- Comment bodies state what is wrong, not how to fix it. Do not hand the author a patch.

The fields mirror one ledger row as defined in [`CODE_REVIEW.md § Probes`](./CODE_REVIEW.md#probes), plus the comments that row produces.

## Boundaries

- **MUST NOT** post comments, submit a review, resolve threads, or otherwise write to GitHub.
- **MUST NOT** modify any file in the working tree.
- **MUST NOT** probe rules other than {{RULE_HEADING}}.
- Returning without a filled `examined` and `evidence` is not a result — the dispatching reviewer will re-run the probe.
