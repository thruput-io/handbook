# CODE REVIEW

Procedural checklist for reviewing pull requests. Serves the rules in [`RULES.md`](./RULES.md) and the quality definition in [`PHILOSOPHY.md`](./PHILOSOPHY.md).

## Definitions

- **Subsection** — a `###`-level heading in [`RULES.md`](./RULES.md) (e.g., `### 1. Domain Modeling, Typing & Primitive obsession`). `### If in doubt` and `### If a task conflicts with these guidelines` govern how an agent behaves, not what the code does; they are not reviewable subsections.
- **Rule** — a `####`-level heading in [`RULES.md`](./RULES.md).
- **Principle** — a `####`-level heading in [`PHILOSOPHY.md`](./PHILOSOPHY.md).
- **Review probe** — a focused attempt to find issues from exactly one rule or one principle.

## Review Standards

### Probes

A probe is complete only when it has produced one **ledger row**:

| field      | content                                                                                                                                                               |
|------------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `rule`     | the rule or principle probed, by heading text                                                                                                                         |
| `examined` | what was actually opened to reach the verdict — files, symbols, call sites, test files                                                                                |
| `verdict`  | `violation` \| `clean` \| `not-applicable`                                                                                                                            |
| `evidence` | for `violation`: file and line. For `clean`: what was checked that would have exposed a violation. For `not-applicable`: why the rule cannot apply to this change set |

A statement that a rule was considered is not a probe. A probe with an empty `examined` field is not a probe.

The minimum bar is **one probe per rule** in [`RULES.md`](./RULES.md) and **one probe per principle** in [`PHILOSOPHY.md`](./PHILOSOPHY.md). Subsections partition the work; they are not the unit of coverage.

`not-applicable` requires a reason tied to the change set. "No findings" is not a reason.

Do not fabricate findings to satisfy a count. A review with zero violations is acceptable; a review with an incomplete ledger is not.

### First-Time Reviews

Do not approve after a shallow pass. A first-time review is complete only when all the following hold:

- The ledger has a row for every rule and every applicable principle.
- Every row's `evidence` field is filled and refers to something in this change set.
- Every `violation` row has a corresponding review comment.
- Any shortage of findings is explained by completed rows, not by absent ones.

If a previous review was rejected solely by the [Pre-Review Content Checks](#2-pre-review-content-checks), treat the next review as a first-time review.

### Subsequent Reviews

Apply the same standards and the same minimum bar. Do not reduce the number of probes and do not narrow scrutiny to topics already commented on. Limit only the **surface** under review to:

- Changes carrying an unresolved comment.
- Changes carrying a comment the **author** resolved.
- Changes new since the last review.

Rebuild the ledger against that surface. A rule that was `clean` last time is probed again if the surface touches it.

As commented changes are reviewed, resolve or unresolve the threads directly in the PR — see [step 6](#6-settle-existing-threads).

## Workflow

### 1. Setup

Fetch PR data:

- Overview: `gh pr view <URL> --json title,body,state,author,headRefName,baseRefName,headRefOid`
- Diff: `gh pr diff <URL>`
- Existing review comments (to avoid duplicates): `gh api repos/{owner}/{repo}/pulls/{n}/comments`

Extract `headRefOid` from the overview response — this is the `commit_id` required for inline comments. Do **not** guess it; do **not** use `HEAD` of the local checkout.

**Read beyond the diff.** Hunks are not enough to evaluate most of [`RULES.md`](./RULES.md) — dead code, layering, primitive leakage, missing tests, and unrepresentable illegal states are all invisible in isolated hunks. Before probing, obtain at `headRefOid`:

- Every changed file, in full.
- The call sites of every changed public symbol.
- The test files covering every changed file, including the case where none exist.

Either `gh pr checkout <URL>` and read locally, or fetch per file with `gh api repos/{owner}/{repo}/contents/{path}?ref=<headRefOid>`.

A probe that could not obtain the context it needed is recorded with that fact in `examined` — never silently downgraded to `clean`.

### 2. Pre-Review Content Checks

If any of the following is true, stop probing and submit a `REQUEST_CHANGES` review whose body names the failing check, with no inline comments:

- Tests are failing.
- The PR has merge conflicts.
- The PR description merely restates the diff (a WHAT summary) without explaining the WHY.
- The PR description does not match what the change set actually does.

This is the only path that skips the ledger.

### 3. Library Search and Rule Evaluation (Run in Parallel)

These are independent and MUST be fanned out concurrently:

- **Library search.** Search for an existing library that could replace non-trivial custom logic in the change set (parsers, retry loops, date math, and similar). If a suitable library exists, add a general PR comment linking to it.
- **Rule evaluation.** Probe every rule in [`RULES.md`](./RULES.md), partitioned by subsection.
- **Principle evaluation.** Probe every principle in [`PHILOSOPHY.md`](./PHILOSOPHY.md).

Both evaluations run to completion regardless of what the other finds. Finding a violation early does not end the pass; neither does finding none.

Merge the results into a single ledger. Fanned-out work that returns without ledger rows is not a result — re-run it.

### 4. Escalate When the Ledger Comes Back Clean

If the ledger is complete and holds no `violation` rows, the review is not finished — probe further before approving:

1. Consult [`references/agent-rules-books-INDEX.md`](./references/agent-rules-books-INDEX.md) and select the ruleset most relevant to what this PR changes.
2. Probe against that ruleset, adding rows to the same ledger.

Approve only after this pass also comes back clean.

### 5. Draft Comments Locally

Build a JSON array of comments in memory (do not post yet), one object per `violation` row, with these fields — and no others, as the API rejects unknown keys:

- `path` — repo-relative file path (e.g. `src/foo.ts`).
- `line` — line number in the file **as of the PR head commit**, not the diff hunk offset. Emit as a bare integer (no quotes).
- `side` — `RIGHT` for lines added/modified in the PR, `LEFT` for removed lines. Default `RIGHT`.
- `body` — the comment body, including the rule citation.

For multi-line comments add `start_line` and `start_side`.

Each comment body:

- Explains the violation. Keep it short.
- MUST cite the violated rule or principle as an absolute repo URL, so the link resolves outside this repo. Anchors are derived as described in [`RULES.md § Priority and precedence`](./RULES.md#priority-and-precedence). Example: `[Strictness over sloppiness](https://github.com/thruput-io/handbook/blob/main/PHILOSOPHY.md#strictness-over-sloppiness)`.
- States what is wrong, not how to fix it. Do not hand the author a patch.

The ledger stays local. It is the completeness record for the review, not review content.

### 6. Settle Existing Threads

Subsequent reviews only. List threads and their state:

```bash
gh api graphql -f query='
  query($owner:String!, $repo:String!, $n:Int!) {
    repository(owner:$owner, name:$repo) {
      pullRequest(number:$n) {
        reviewThreads(first:100) {
          nodes { id isResolved isOutdated path line comments(first:1){nodes{body}} }
        }
      }
    }
  }' -F owner={owner} -F repo={repo} -F n={n}
```

Then, per thread `id`:

- Fixed: `gh api graphql -f query='mutation($t:ID!){ resolveReviewThread(input:{threadId:$t}){ thread{ id } } }' -F t=<id>`
- Resolved by the author but not actually fixed: `unresolveReviewThread` with the same shape, plus a new comment in step 5.

### 7. Submit as a Single Review

Do not submit until every ledger row is filled. An unfilled row means the review is unfinished, whatever the findings count.

Build a JSON payload:

```json
{
  "commit_id": "<headRefOid>",
  "body": "<overall review body>",
  "event": "APPROVE | REQUEST_CHANGES | COMMENT",
  "comments": [ /* array from step 5 */ ]
}
```

Submit atomically:

```bash
gh api -X POST repos/{owner}/{repo}/pulls/{n}/reviews --input review.json
```

This produces one review, one notification, and all comments are grouped. Do **not** use `POST /pulls/{n}/comments` in a loop — that creates N standalone review comments, N notifications, and is not atomic.
