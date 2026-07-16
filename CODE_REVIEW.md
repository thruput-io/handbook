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

### 1. Pre-Review Content Checks

Reject the PR immediately if any of the following are true:

- Tests are failing.
- The PR has merge conflicts.
- The PR description merely restates the diff (a WHAT summary) without explaining the WHY.
- The PR description does not match what has actually been done in PRs change set

### 2. Library Search and Rule Evaluation (run in parallel)

These steps are independent and MUST be fanned out concurrently:

- **Library search.** Spawn a subagent to search the web for an existing library that could replace non-trivial custom logic in the PR (parsers, retry loops, date math, and similar). If a suitable library exists, add a general PR comment linking to it.
- **Rule evaluation.** Spawn one subagent per subsection in [`RULES.md`](./RULES.md). Each subagent inspects every rule in its assigned subsection and identifies both direct and indirect violations.

### 3. Commenting

For every problem found:

- Leave a clear review comment.
- Reference the violated rule or principle with an absolute repo URL so the link works from anywhere (e.g., PR comments, external tools). Each rule has a stable HTML anchor id like `philosophy-achievement-strictness-over-sloppiness`. Example: `[Strictness over sloppiness](https://github.com/thruput-io/handbook/blob/main/PHILOSOPHY.md#philosophy-achievement-strictness-over-sloppiness)`.
- Provide actionable guidance when possible.
