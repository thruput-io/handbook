# CODE REVIEW

Procedural checklist for reviewing pull requests. Serves the rules in [`RULES.md`](./RULES.md) and the quality definition in [`PHILOSOPHY.md`](./PHILOSOPHY.md).

## Definitions

- **Subsection** — a `###`-level heading in [`RULES.md`](./RULES.md) (e.g., `### 1. Domain Modeling, Typing & Primitive obsession`). `### If in doubt` and `### If a task conflicts with these guidelines` govern how an agent behaves, not what the code does; they are not reviewable subsections.
- **Rule** — a `####`-level heading in [`RULES.md`](./RULES.md).
- **Principle** — a `##`-level section in [`PHILOSOPHY.md`](./PHILOSOPHY.md). Principles are not probed: they carry no enforceable requirement, so a probe against one could only return an unfalsifiable verdict. They supply the vocabulary for describing a finding, and the direction to lean when no rule decides the question.
- **Review probe** — a focused attempt to find issues from exactly one rule
- **git-tool** — the CLI for the host the PR lives on: `gh` for GitHub, or `az` with the `azure-devops` extension for Azure DevOps (`dev.azure.com`). Pick it from the PR URL. Every command and payload this workflow needs is in the matching [`gh-cheat-sheet.md`](./gh-cheat-sheet.md) or [`az-cheat-sheet.md`](./az-cheat-sheet.md), referred to below as `{git-tool}-cheat-sheet.md`.
- **head commit** — the commit the review is anchored to: `headRefOid` on GitHub, `lastMergeSourceCommit.commitId` on Azure DevOps. Every file read and every inline comment resolves against it.
- **change set** — the lines this PR adds or removes at the head commit.
- **checkout** — if the working directory is the repository, checkout, otherwise new checkout.
- **surface** — the code a violation may be reported against. On a first-time review the surface is the change set. On a subsequent review it is narrowed as [Subsequent Reviews](#subsequent-reviews) sets out.
- **full context** — the surface plus the reading in [step 1](#1-setup): every changed file in full, the call sites of changed public symbols, and the covering test files. Context is what a verdict is *reached from*, never what a verdict is reported *against*.

## Review Standards

### Probes

A probe is complete only when it has produced one **ledger row**:

| field      | content                                                                                                                                                               |
|------------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `rule`     | the rule probed, by heading text                                                                                                                                      |
| `examined` | what was actually opened to reach the verdict — files, symbols, call sites, test files                                                                                |
| `verdict`  | `violation` \| `clean` \| `not-applicable`                                                                                                                            |
| `evidence` | for `violation`: file and line, inside the surface — or, for code the surface made dead, the dead line plus the surface line that killed it. For `clean`: what was checked that would have exposed a violation. For `not-applicable`: why the rule cannot apply to the full context |

A statement that a rule was considered is not a probe. A probe with an empty `examined` field is not a probe.

The minimum bar is **one probe per rule** in [`RULES.md`](./RULES.md). Subsections partition the work; they are not the unit of coverage.

`not-applicable` requires a reason tied to full context. "No findings" is not a reason.

Do not fabricate findings to satisfy a count. A review with zero violations is acceptable; a review with an incomplete ledger is not.

### First-Time Reviews

Do not approve after a shallow pass. A first-time review is complete only when all the following hold:

- The ledger has a row for every rule.
- Every row's `evidence` field is filled and refers to something in this full context.
- Every `violation` row has a corresponding review comment.
- Any shortage of findings is explained by completed rows, not by absent ones.

If a previous review was rejected solely by the [Pre-Review Content Checks](#2-pre-review-content-checks), treat the next review as a first-time review.

### Subsequent Reviews

Apply the same standards and the same minimum bar. Do not reduce the number of probes and do not narrow scrutiny to topics already commented on. Limit only the **surface** under review to:

- Changes carrying an unresolved comment.
- Changes carrying a comment the **author** has resolved since the prior review.
- Changes new since the prior review.

Rebuild the ledger against that surface. A rule that was `clean` last time is probed again if the surface touches it.

As commented changes are reviewed, resolve or unresolve the threads directly in the PR — see [step 6](#6-settle-existing-threads).

## Workflow

### 1. Setup

The git-tool must be available.

Fetch the PR overview, the changed files, and the existing review comments — the last so this review does not duplicate a comment already on the PR. On Azure DevOps, filter the system-generated threads out of that comparison; counting them as review comments corrupts the check.

Extract the head commit and the PR description from the overview response — inline comments are posted against the head commit, and the description is handed to every probe in [step 3](#3-rule-evaluation), so it is fetched once here rather than once per subagent. Do **not** guess the head commit; do **not** use `HEAD` of the local checkout.

**Read beyond the change set.** Hunks are not enough to evaluate most of [`RULES.md`](./RULES.md) — dead code, layering, primitive leakage, missing tests, and unrepresentable illegal states are all invisible in isolated hunks. Before probing, obtain at the head commit:

- Every changed file, in full.
- The call sites of every changed public symbol, limited to the repository holding the PR.
- The test files covering the change set, including the case where none exist.

The full context widens what is read; it does not widen what is reported. A `violation` MUST anchor inside the surface. A problem that already existed in the full context, on a line the surface does not touch, is not a finding of this review.

One thing outside the surface is reportable: code the surface makes dead — a symbol whose last caller this PR removes, a branch this PR makes unreachable. Anchor it at the dead code, and name in `evidence` the surface line that killed it. Dead code the surface merely failed to clean up is not this.

Either check the PR out and read locally, or fetch per file — see `{git-tool}-cheat-sheet.md § Read files at the head commit`. Azure DevOps returns no textual diff at all, so there the full-file read is the only option.

A probe that could not obtain the context it needed is recorded with that fact in `examined` — never silently downgraded to `clean`.

### 2. Pre-Review Content Checks

If any of the following is true, stop probing and submit a changes-requested verdict whose body names the failing check, with no inline comments — `REQUEST_CHANGES` on GitHub, a `wait-for-author` or `reject` vote on Azure DevOps:

- Tests are failing.
- The PR has merge conflicts.
- The PR description merely restates the change set (a WHAT summary) without explaining the WHY.
- The PR description does not match what the change set actually does.

This is the only path that skips the ledger.

### 3. Rule Evaluation

Probe every rule in [`RULES.md`](./RULES.md), partitioned by subsection. The pass runs to completion whatever it finds: a violation early does not end it, and neither does a run of `clean` verdicts.

**Fan out one subagent per probe.** Each probe MUST run in its own subagent, dispatched with [`PROBE_SUBAGENT_TEMPLATE.md`](./PROBE_SUBAGENT_TEMPLATE.md) filled in. Do not probe several rules in one subagent, and do not probe rules in the reviewing context itself.

**Some rules cannot be probed by reading the full context.** The ladder in [`RULES.md § 3. Simplicity`](./RULES.md#3-simplicity) asks whether this code needed to be written at all, and answering that takes a search rather than an inspection — a different search per rung:

| rule                                                                          | what the probe searches                                                                                                               |
|-------------------------------------------------------------------------------|---------------------------------------------------------------------------------------------------------------------------------------|
| [Reuse code in this codebase](./RULES.md#reuse-code-in-this-codebase)         | this repository, for an existing component or for code that should be refactored into one                                             |
| [Use the platform or framework](./RULES.md#use-the-platform-or-framework)     | the published documentation for the language, runtime, and framework already in use, on the web, **at the version this project pins** |
| [Use an external component](./RULES.md#use-an-external-component)             | the package registry for this ecosystem                                                                                               |
| [Use an external tool or service](./RULES.md#use-an-external-tool-or-service) | existing tools, and services callable over an API                                                                                     |

A probe on one of these that examined only the change set has not run. Its `examined` field MUST name the searches performed and the queries used, and a `clean` verdict MUST say what was searched for and not found. These are the probes most often skipped, because a negative result feels like no result — but an unsearched rung and an empty rung are different findings, and the `examined` field is the only thing that distinguishes them.

Enumerate every rule (`####` in [`RULES.md`](./RULES.md)) first; that enumeration is the probe list, and its length is the number of subagents to dispatch. Launch them concurrently.

Only the reviewing context talks to the PR host. Subagents read; they never post, resolve threads, or submit — and they never fetch PR metadata: the description, the changed-file list, the head commit, and the surface are resolved here and handed to them.

**A probe reads the repository under review and its own instructions — nothing else on the host filesystem.** On disk that is the local checkout of this PR, or the files fetched at the head commit where there is none. The instructions are a closed set: the rule at its source URL, the documents that source links for the rule, and `{git-tool}-cheat-sheet.md`. Other checkouts, agent configuration, and the rest of the reviewer's home directory are out of scope; a probe that needed something there records that in `examined` rather than reading it. The ladder searches in the table above are unaffected, because none of them is a read of the host filesystem: they query the package registry, callable services, and the published documentation for the platform and framework on the web. Platform and framework capability is established from those published docs at the version this project pins — never from a local install tree, and never from memory of the framework.

Merge the returned rows into a single ledger, and the returned comments into the array built in [step 5](#5-draft-comments-locally). Fanned-out work that returns without ledger rows is not a result — re-run it.

**Wait for every probe before moving on.** The probe list from the enumeration above is the expected row count: the ledger is complete only when it holds one row per dispatched subagent. Waiting is a hard barrier — do not draft comments and do not submit while any probe is still outstanding. A `violation` returned early does not end the pass and does not license an early submission; neither does a run of `clean` verdicts. The only path that submits without a complete ledger is [step 2](#2-pre-review-content-checks).

Submitting while probes are still running does not produce a partial review; it produces a wrong one. It reports a violation count the surface does not have, and it makes the rules whose subagents had not yet returned indistinguishable from rules that came back `clean`.

### 4. Escalate When the Ledger Comes Back Clean

If the ledger is complete and holds no `violation` rows, the review is not finished — probe further before approving:

1. Consult [`references/agent-rules-books-INDEX.md`](https://github.com/thruput-io/handbook/blob/main/references/agent-rules-books-INDEX.md) — or the copy bundled with the tooling that invoked this review — and select the ruleset whose focus matches what this PR changes.
2. The index is a pointer, not a ruleset. Fetch the selected ruleset at its `canonical_url` in [`ciembor/agent-rules-books`](https://github.com/ciembor/agent-rules-books) and read the actual rules. Do not probe from the index's one-line summary, or from memory of the book.
3. Probe that ruleset the same way as [step 3](#3-rule-evaluation): one subagent per rule, [`PROBE_SUBAGENT_TEMPLATE.md`](./PROBE_SUBAGENT_TEMPLATE.md) filled in with the ruleset URL as `{{RULE_SOURCE_URL}}`. Add the returned rows to the same ledger.

Approve only after this pass also comes back clean.

### 5. Draft Comments Locally

Build the comments in memory (do not post yet), one per `violation` row. The payload shape is host-specific — a comment object on GitHub, a thread with a `threadContext` on Azure DevOps; both are in `{git-tool}-cheat-sheet.md`.

A violation with no single line to blame becomes a **PR-level comment** instead: an existing component that replaces a whole module, or a standard the change set as a whole does not follow. It carries no `path` or `line` — on GitHub it goes in the review body, on Azure DevOps it is a thread without a `threadContext`. It is drafted here and submitted with everything else in step 7, never posted on its own.

Two properties carry review meaning rather than syntax, and are decided here whatever the host: the line is the line **as of the head commit**, never a diff hunk offset, and it is a line in the surface rather than merely a line in a file the surface touches; and a comment anchors to the removed-line side only when the violation is in a removed line.

Each comment body:

- Explains the violation. Keep it short.
- MUST cite the violated rule as an absolute repo URL, so the link resolves outside this repo. Anchors are derived as described in [`RULES.md § Priority and precedence`](./RULES.md#priority-and-precedence). Example: `[No suppressed exit status](https://github.com/thruput-io/handbook/blob/main/RULES.md#no-suppressed-exit-status)`. A principle from [`PHILOSOPHY.md`](./PHILOSOPHY.md) MAY be named to characterize the violation, but it never stands in for the rule.
- States what is wrong, not how to fix it. Do not hand the author a patch.

The ledger stays local. It is the completeness record for the review, not review content.

### 6. Settle Existing Threads

Subsequent reviews only. List the threads and their state, then act per thread — commands in `{git-tool}-cheat-sheet.md`:

- Fixed: resolve the thread.
- Resolved by the author but not actually fixed: unresolve it, and add a new comment in step 5.

### 7. Submit

Two gates, both checked before anything is posted:

- **The ledger is whole.** It holds one row per probe on the list, and every row is filled. A missing row means a probe never returned and the review is unfinished, whatever the findings count.
- **Every `violation` row is in the payload.** Each one gets its inline comment — or its PR-level comment, where no single line is to blame — and the review body accounts for all of them. A violation that appears in the ledger but not in what is submitted has been found and then dropped, which is worse than not having probed for it — the author is told the surface is cleaner than the review actually established.

Submit every comment from step 5 together with the verdict, anchored to the head commit. How atomic that can be depends on the host:

- **GitHub** — one payload carries every inline comment plus the verdict, so submit exactly **one** review: one review, one notification, comments grouped. Do **not** post comments one at a time in a loop — that is N standalone comments, N notifications, and not atomic. See [`gh-cheat-sheet.md § Submit one atomic review`](./gh-cheat-sheet.md#submit-one-atomic-review).
- **Azure DevOps** — no atomic endpoint exists. Each thread is its own request and the vote is a separate call, so N comments unavoidably mean N requests. Drafting locally in step 5 is what replaces atomicity: post every thread **before** casting the vote, so the verdict never lands ahead of its evidence, and on a retry reconcile against the existing threads rather than duplicating them. See [`az-cheat-sheet.md § No atomic review`](./az-cheat-sheet.md#no-atomic-review).
