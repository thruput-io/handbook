# CODE REVIEW

Procedural checklist for reviewing pull requests. Serves the rules in [`RULES.md`](./RULES.md) and the quality definition in [`PHILOSOPHY.md`](./PHILOSOPHY.md).

A **subsection** below refers to a `###`-level heading in [`RULES.md`](./RULES.md) (e.g., `### 1. Domain Modeling, Typing & Primitive obsession`).

## Review Standards

### First-Time Reviews

Do not approve after a shallow pass. A first-time review is complete only when all of the following hold:

- Every subsection in [`RULES.md`](./RULES.md) was evaluated, and each has either a concrete violation or a short note that no applicable violation was found.
- Every applicable principle in [`PHILOSOPHY.md`](./PHILOSOPHY.md) was evaluated the same way.
- Every actual issue discovered has a corresponding review comment.
- Any shortage of findings is explained by completed checks, not by skipping review effort.

A **review probe** is a focused attempt to find issues from a distinct rule, subsection, or principle. In practice, one probe per subsection in [`RULES.md`](./RULES.md) plus each applicable [`PHILOSOPHY.md`](./PHILOSOPHY.md) principle is the minimum bar.

Do not fabricate findings to satisfy a count.

If the PR appears clean before the subsections are exhausted, continue reviewing against [`PHILOSOPHY.md`](./PHILOSOPHY.md) until the depth requirements are satisfied. Once [`PHILOSOPHY.md`](./PHILOSOPHY.md) is also exhausted, consult [`references/agent-rules-books-INDEX.md`](./references/agent-rules-books-INDEX.md) and probe against the ruleset most relevant to the PR.

If a previous review was rejected solely by the [Pre-Review Content Checks](#1-pre-review-content-checks), treat the next review as a first-time review.

### Subsequent Reviews

- Scrutinize every submitted fix.
- Use [`PHILOSOPHY.md`](./PHILOSOPHY.md) to justify reopening comments and educate the developer; fall back to [`references/agent-rules-books-INDEX.md`](./references/agent-rules-books-INDEX.md) when a more specific canonical source is needed.
- Reopen previously resolved comments when the underlying issue was not fully addressed.

## Workflow

K### 1. Setup

Check auth (do not prompt unless needed):

    Run `gh auth status`. Ask the user which identity to use if auth is missing, or if multiple accounts are listed and only identity is same as PR author.

Fetch PR data:

- Overview: `gh pr view <URL> --json title,body,state,author,headRefName,baseRefName,headRefOid`
- Diff: `gh pr diff <URL>`
- Existing review comments (to avoid duplicates): `gh api repos/{owner}/{repo}/pulls/{n}/comments`

Extract `headRefOid` from the overview response — this is the `commit_id` required for inline comments. Do **not** guess it; do **not** use `HEAD` of the local checkout.

### 2. Pre-Review Content Checks

Reject the PR immediately if any of the following are true:

- Tests are failing.
- The PR has merge conflicts.
- The PR description merely restates the diff (a WHAT summary) without explaining the WHY.
- The PR description does not match what has actually been done in PRs change set

### 3. Library Search and Rule Evaluation (Run in Parallel)

These steps are independent and MUST be fanned out concurrently:

- **Library search.** Spawn a subagent to search the web for an existing library that could replace non-trivial custom logic in the PR (parsers, retry loops, date math, and similar). If a suitable library exists, add a general PR comment linking to it.
- **Rule evaluation.** Spawn one subagent per subsection in [`RULES.md`](./RULES.md). Each subagent inspects every rule in its assigned subsection and identifies both direct and indirect violations.

### 4. Draft Comments Locally

Build a JSON array of comments in memory (do not post yet), one object per comment, with these fields:

- `path` — repo-relative file path (e.g. `src/foo.ts`).
- `line` — line number in the file **as of the PR head commit**, not the diff hunk offset. Emit as a bare integer (no quotes).
- `side` — `RIGHT` for lines added/modified in the PR, `LEFT` for removed lines. Default `RIGHT`.
- `body` — the comment body.
- `rule-reference` — see below.

For multi-line comments add `start_line` and `start_side`.

For every problem found:

- Comment that explains the violation. Keep it short.
- MUST reference the violated rule or principle with an absolute repo URL so the link works from anywhere (e.g., PR comments, external tools). Each rule has a stable HTML anchor id like `philosophy-achievement-strictness-over-sloppiness`. Example: `[Strictness over sloppiness](https://github.com/thruput-io/handbook/blob/main/PHILOSOPHY.md#philosophy-achievement-strictness-over-sloppiness)`.
- MUST NOT provide actionable guidance.

### 5. Submit as a Single Review

Build a JSON payload:

```json
{
  "commit_id": "<headRefOid>",
  "body": "<overall review body>",
  "event": "APPROVE | REQUEST_CHANGES | COMMENT",
  "comments": [ /* array from step 4 */ ]
}
```

Submit atomically:

```bash
gh api -X POST repos/{owner}/{repo}/pulls/{n}/reviews --input review.json
```

This produces one review, one notification, and all comments are grouped. Do **not** use `POST /pulls/{n}/comments` in a loop — that creates N standalone review comments, N notifications, and is not atomic.
