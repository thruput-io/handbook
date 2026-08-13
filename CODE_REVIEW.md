# CODE REVIEW

Procedural checklist for reviewing pull requests. Serves the rules in [`RULES.md`](./RULES.md) and the quality definition in [`PHILOSOPHY.md`](./PHILOSOPHY.md).

## Definitions

- **Subsection** — a `###`-level heading in [`RULES.md`](./RULES.md) (e.g., `### 1. Domain Modeling, Typing & Primitive obsession`). `### If in doubt` and `### If a task conflicts with these guidelines` govern how an agent behaves, not what the code does; they are not reviewable subsections.
- **Rule** — a `####`-level heading in [`RULES.md`](./RULES.md).
- **Principle** — a `####`-level heading in [`PHILOSOPHY.md`](./PHILOSOPHY.md).
- **Review probe** — a focused attempt to find issues from exactly one rule or one principle
- **git-tool** — the CLI for the host the PR lives on: `gh` for GitHub, or `az` with the `azure-devops` extension for Azure DevOps (`dev.azure.com`). Pick it from the PR URL. Every command and payload this workflow needs is in the matching [`gh-cheat-sheet.md`](./gh-cheat-sheet.md) or [`az-cheat-sheet.md`](./az-cheat-sheet.md), referred to below as `{git-tool}-cheat-sheet.md`.
- **head commit** — the commit the review is anchored to: `headRefOid` on GitHub, `lastMergeSourceCommit.commitId` on Azure DevOps. Every file read and every inline comment resolves against it.

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

The git-tool must be available.

Fetch the PR overview, the changed files, and the existing review comments — the last so this review does not duplicate a comment already on the PR. On Azure DevOps, filter the system-generated threads out of that comparison; counting them as review comments corrupts the check.

Extract the head commit from the overview response — inline comments are posted against it. Do **not** guess it; do **not** use `HEAD` of the local checkout.

**Read beyond the diff.** Hunks are not enough to evaluate most of [`RULES.md`](./RULES.md) — dead code, layering, primitive leakage, missing tests, and unrepresentable illegal states are all invisible in isolated hunks. Before probing, obtain at the head commit:

- Every changed file, in full.
- The call sites of every changed public symbol.
- The test files covering every changed file, including the case where none exist.

Either check the PR out and read locally, or fetch per file — see `{git-tool}-cheat-sheet.md § Read files at the head commit`. Azure DevOps returns no textual diff at all, so there the full-file read is the only option.

A probe that could not obtain the context it needed is recorded with that fact in `examined` — never silently downgraded to `clean`.

### 2. Pre-Review Content Checks

If any of the following is true, stop probing and submit a changes-requested verdict whose body names the failing check, with no inline comments — `REQUEST_CHANGES` on GitHub, a `wait-for-author` or `reject` vote on Azure DevOps:

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

**Fan out one subagent per probe.** Each probe MUST run in its own subagent, dispatched with [`PROBE_SUBAGENT_TEMPLATE.md`](./PROBE_SUBAGENT_TEMPLATE.md) filled in. Do not probe several rules in one subagent, and do not probe rules in the reviewing context itself. The library search is one further subagent.

Enumerate every rule (`####` in [`RULES.md`](./RULES.md)) and every principle (`####` in [`PHILOSOPHY.md`](./PHILOSOPHY.md)) first; that enumeration is the probe list, and its length is the number of subagents to dispatch. Launch them concurrently.

Only the reviewing context talks to the PR host. Subagents read; they never post, resolve threads, or submit.

Merge the returned rows into a single ledger, and the returned comments into the array built in [step 5](#5-draft-comments-locally). Fanned-out work that returns without ledger rows is not a result — re-run it.

**Wait for every probe before moving on.** The probe list from the enumeration above is the expected row count: the ledger is complete only when it holds one row per dispatched subagent. Waiting is a hard barrier — do not draft comments and do not submit while any probe is still outstanding. A `violation` returned early does not end the pass and does not license an early submission; neither does a run of `clean` verdicts. The only path that submits without a complete ledger is [step 2](#2-pre-review-content-checks).

Submitting while probes are still running does not produce a partial review, it produces a wrong one. It reports a violation count the change set does not have, and it makes the rules whose subagents had not yet returned indistinguishable from rules that came back `clean`.

### 4. Escalate When the Ledger Comes Back Clean

If the ledger is complete and holds no `violation` rows, the review is not finished — probe further before approving:

1. Consult [`references/agent-rules-books-INDEX.md`](https://github.com/thruput-io/handbook/blob/main/references/agent-rules-books-INDEX.md) — or the copy bundled with the tooling that invoked this review — and select the ruleset whose focus matches what this PR changes.
2. The index is a pointer, not a ruleset. Fetch the selected ruleset at its `canonical_url` in [`ciembor/agent-rules-books`](https://github.com/ciembor/agent-rules-books) and read the actual rules. Do not probe from the index's one-line summary, or from memory of the book.
3. Probe that ruleset the same way as [step 3](#3-library-search-and-rule-evaluation-run-in-parallel): one subagent per rule, [`PROBE_SUBAGENT_TEMPLATE.md`](./PROBE_SUBAGENT_TEMPLATE.md) filled in with the ruleset URL as `{{RULE_SOURCE_URL}}`. Add the returned rows to the same ledger.

Approve only after this pass also comes back clean.

### 5. Draft Comments Locally

Build the comments in memory (do not post yet), one per `violation` row. The payload shape is host-specific — a comment object on GitHub, a thread with a `threadContext` on Azure DevOps; both are in `{git-tool}-cheat-sheet.md`.

Two properties carry review meaning rather than syntax, and are decided here whatever the host: the line is the line **as of the head commit**, never a diff hunk offset; and a comment anchors to the removed-line side only when the violation is in a removed line.

Each comment body:

- Explains the violation. Keep it short.
- MUST cite the violated rule or principle as an absolute repo URL, so the link resolves outside this repo. Anchors are derived as described in [`RULES.md § Priority and precedence`](./RULES.md#priority-and-precedence). Example: `[Strictness over sloppiness](https://github.com/thruput-io/handbook/blob/main/PHILOSOPHY.md#strictness-over-sloppiness)`.
- States what is wrong, not how to fix it. Do not hand the author a patch.

The ledger stays local. It is the completeness record for the review, not review content.

### 6. Settle Existing Threads

Subsequent reviews only. List the threads and their state, then act per thread — commands in `{git-tool}-cheat-sheet.md`:

- Fixed: resolve the thread.
- Resolved by the author but not actually fixed: unresolve it, and add a new comment in step 5.

### 7. Submit

Two gates, both checked before anything is posted:

- **The ledger is whole.** It holds one row per probe on the list, and every row is filled. A missing row means a probe never returned and the review is unfinished, whatever the findings count.
- **Every `violation` row is in the payload.** Each one gets its inline comment, and the review body accounts for all of them. A violation that appears in the ledger but not in what is submitted has been found and then dropped, which is worse than not having probed for it — the author is told the change set is cleaner than the review actually established.

Submit every comment from step 5 together with the verdict, anchored to the head commit. How atomic that can be depends on the host:

- **GitHub** — one payload carries every inline comment plus the verdict, so submit exactly **one** review: one review, one notification, comments grouped. Do **not** post comments one at a time in a loop — that is N standalone comments, N notifications, and not atomic. See [`gh-cheat-sheet.md § Submit one atomic review`](./gh-cheat-sheet.md#submit-one-atomic-review).
- **Azure DevOps** — no atomic endpoint exists. Each thread is its own request and the vote is a separate call, so N comments unavoidably mean N requests. Drafting locally in step 5 is what replaces atomicity: post every thread **before** casting the vote, so the verdict never lands ahead of its evidence, and on a retry reconcile against the existing threads rather than duplicating them. See [`az-cheat-sheet.md § No atomic review`](./az-cheat-sheet.md#no-atomic-review).
