# PLANNING

Reach a precise, limited, implementable understanding of **one** problem, together with the
human, and leave behind a plan another agent can execute without guessing.

Same RFC 2119 priority markers and the same anchor convention as
[`RULES.md`](./RULES.md#priority-and-precedence): a rule's anchor is its heading text,
lowercased, punctuation dropped, spaces replaced by hyphens.

This document governs the planning activity only. [`RULES.md`](./RULES.md),
[`PHILOSOPHY.md`](./PHILOSOPHY.md), and [`WORKFLOW.md`](./WORKFLOW.md) remain a higher
authority; where this document and one of them disagree, they win and you **MUST** raise the
conflict rather than resolve it silently.

## Core intent

The plan is co-authored with the human in every detail. You:

- identify and prioritize the goals;
- challenge assumptions and expose unknowns;
- investigate the codebase, documentation, existing tools, and viable alternatives;
- use code and executable experiments to answer questions and verify findings;
- preserve positive, negative, and abandoned findings;
- reach shared understanding through deliberate questioning; and
- produce a standalone plan that an implementing agent can follow and verify.

### No silent scope change

**MUST NOT** — Expand, narrow, or reinterpret the agreed scope without the human's explicit
agreement, recorded in the plan.

### No unapproved decisions

**MUST NOT** — Decide anything material to the design without putting it to the human first.

### No optimizing for a short session

**MUST NOT** — Trade depth for finishing sooner. A plan that ends the session quickly and
leaves the implementing agent guessing has failed.

### No implementation

**MUST NOT** — Write, modify, or refactor production code during planning. Experiments under
[Exploratory tests](#exploratory-tests) are the only code you write.

## Preflight

Run these checks **before** any questioning, in this order. Each is a hard stop.

### Verify tool permissions first

**MUST** — Confirm you can, in this session: write files, run the project's tests, run
`git commit`, and reach the network for research. State which of these you verified.

### Stop when a permission is missing

**MUST** — Stop and tell the human exactly what is missing if any of those four cannot be
verified. **MUST NOT** — Continue with a workaround or an assumed permission. Planning under
unrealistic constraints produces a plan that cannot be implemented.

### Stop on a dirty repository

**MUST** — Check `git status`. If the working tree is not clean, stop and tell the human what
must be resolved. **MUST NOT** — Stash, reset, discard, checkout over, or otherwise touch
their changes. See [Clean before large task](./WORKFLOW.md#clean-before-large-task).

### Read the handbook and the ADRs

**MUST** — Read [`RULES.md`](./RULES.md), [`PHILOSOPHY.md`](./PHILOSOPHY.md), and
[`WORKFLOW.md`](./WORKFLOW.md). Then read the project's ADRs — conventionally `docs/adr/` or
`docs/decisions/`; ask the human for the location if neither exists — from the highest-numbered
downward, stopping once older ADRs no longer touch the problem area. Record every ADR that
constrains the plan, and every conflict between them, in the plan's `Discussions` section.

### Never destructive

**MUST NOT** — Use destructive git commands, or modify files unrelated to the plan, at any
point in this workflow.

## Interaction: the grill-me loop

Exploration is an interview, not a series of status updates.

### One decision per turn

**MUST** — Structure each turn as: the current uncertainty or decision; why it matters; your
recommended answer when evidence justifies one; and one focused question that moves the
discussion forward.

**MAY** — Ask a short numbered batch instead of one question when the questions are genuinely
independent and the human would otherwise wait through several round trips.

### Challenge, don't accept

**MUST** — Challenge vague goals, optimistic assumptions, hidden scope, and least-effort
interpretations. Keep asking until the human's intent and the consequences of each important
decision are understood.

### Code over opinion

**MUST** — Prefer executable evidence over prose whenever a question can be settled by running
something. See [No assumptions without evidence](./WORKFLOW.md#no-assumptions-without-evidence).

### Narrate intent and result

**MUST** — Say what you are about to do and why before each investigation, and record what it
returned afterwards. **MUST NOT** — Replace the dialogue with generic progress reports.

### Keep an open-questions list

**MUST** — Maintain a visible list of unresolved questions in the plan, and update it every
turn. The human may close any item on it; that closure is a decision and is recorded like any
other.

### Return to exploration on a new unknown

**MUST** — Go back to [Phase 2](#phase-2-ideation-and-exploration), resolve the unknown, and
record the decision before continuing, whenever one surfaces later in the session.

### Say so when no plan is warranted

**MUST** — Tell the human, with evidence, if investigation shows the problem is already solved,
is a one-line fix, or is not worth a plan. Record the finding. The human decides whether to
continue; you **MUST NOT** end the session on your own judgement.

## Artifacts

```text
docs/plans/{plan-name}/
├── 001-{plan-name}.md                              the plan
├── research/{report-name}/{files...}               research reports
└── progress/{plan-number}-attempt-{n}-{date}.md    written during implementation, not planning
```

Exploratory tests live in the project's own test tree, never under `docs/`. See
[Exploratory tests](#exploratory-tests).

### Name the problem, not the solution

**MUST** — Name the plan after the stable problem, and cover one problem per plan:

- `end-user-authentication`, not `oauth2-client-library`;
- `memory-persistence`, not `memq-implementation`;
- `basic-automated-builds`, not `build-pipeline-and-test-coverage-enforcement`.

### Update an unmerged plan in place

**MUST** — Edit the existing file when the current plan has not yet reached `main`. **MUST
NOT** — Create a new numbered file for it.

### Merged plans are immutable

**MUST NOT** — Edit a plan that has been merged to `main`. Check with
`git log origin/main -- docs/plans/{plan-name}/`; any file listed there is frozen.

### Increment by copying beside the original

**MUST** — Copy the merged plan to the next number in the same folder when its problem
resurfaces — `001-{plan-name}.md` → `002-{plan-name}.md` — leave the original byte-for-byte
untouched, and edit only the copy. The new plan **MUST** link back to the one it supersedes and
state what changed and why. The branch takes the new number, e.g. `002-{plan-name}`.

### Exploratory tests

**MUST** — Place every experiment in the project's existing test tree, under
`{test-context}/exploratory/{plan-name}/`, where `{test-context}` is the test root that already
serves the module or language under investigation. They then compile, run, and report through
the project's normal toolchain like any other test. **MUST NOT** — Put experiments under
`docs/`, or run them as untracked ad-hoc scripts. Read-only inspection of the repository is not
an experiment and needs no file.

### Commit everything, including failures

**MUST** — Commit each experiment and research report with its result as soon as it has one,
including the ones that failed, disproved the idea, or were abandoned. A negative result the
human never sees will be rediscovered at implementation time at full cost.

## Plan format

Copy [`PLAN_TEMPLATE.md`](./PLAN_TEMPLATE.md) to `docs/plans/{plan-name}/001-{plan-name}.md` and
fill it in. Its sections, and the rules that govern them, are below. The template is the
authority on heading levels.

### Implementing Agent Instructions

**MUST** — Complete this section yourself. It states how the implementing agent works, when
implementation is complete, how to verify it, and the progress-log obligations in
[Progress logs](#progress-logs). **MUST NOT** — Leave any part of it as a placeholder for the
implementing agent to define.

### Background, goals and non-goals

**MUST** — Give a prioritized, testable list of goals that express the human's intent, not a
list of implementation steps. **MUST** — List the non-goals: what is deliberately excluded, so
the boundary is explicit rather than inferred.

### Record the cheapest passing interpretation

**MUST** — Record, for every goal, the cheapest implementation that would technically satisfy
its wording while missing the intent, and how the goal's wording excludes it. Revise the goal
with the human until that loophole is closed. A goal without this entry is not finished.

### Summary

**MUST** — Explain in short prose how the goals will be achieved.

### Assumptions, risks and preconditions

**MUST** — List every assumption the plan rests on, how each was tested (or that it was not),
and what must already be true before implementation starts. See
[Risk assumptions in plan](./WORKFLOW.md#risk-assumptions-in-plan).

### References

**MUST** — Record, for each research question: the question, the short answer, the evidence,
and a path to the report under `research/`. Link the tracer-bullet tests that confirmed or
disproved each assumption. Record negative findings and abandoned approaches alongside the
successful ones.

### Rejected alternatives

**MUST** — Record, for each rejected alternative, what it was, the evidence gathered, and why
it was rejected — including the human's rationale when the rejection was theirs.

### Discussions

**MUST** — Record every non-trivial decision and the reasoning behind it, including ADR
conflicts found during [Preflight](#preflight).

### Execution Plan

**MUST** — Give a step-by-step plan divided into milestones. Every milestone has a named,
human-readable verification test. **MUST** — Include a goal-to-milestone coverage table showing
that every goal is delivered by at least one milestone; a milestone may deliver part of a goal.

**MUST** — Specify one command or script that runs all tests relevant to the plan and reports
the result unambiguously, state where it lives, and state whether it already exists or the
implementing agent creates it as its first milestone.

**MUST NOT** — Draft this section before the human has co-authored and accepted the full detail
of everything above it.

## Progress logs

Progress logs belong to implementation, not to planning. The planning agent never writes one;
it writes the instructions that make the implementing agent write them. These obligations go in
[Implementing Agent Instructions](#implementing-agent-instructions) — the template already
carries them.

### One log per attempt

**MUST** — The implementing agent opens
`docs/plans/{plan-name}/progress/{plan-number}-attempt-{n}-{date}.md` at the start of each
attempt, where `{n}` is one higher than the highest existing attempt and `{date}` is
`YYYY-MM-DD`, and appends to it as work proceeds.

### Append-only

**MUST NOT** — Rewrite, tidy, condense, or delete an entry in a progress log once written. It
is a record of what happened, not a summary of the current state. Corrections are new entries.

### Committed progress is immutable

**MUST NOT** — Amend or force-push a commit containing progress-log entries. A log that can be
rewritten cannot be trusted as evidence of what was tried.

### Failed attempts are published, not discarded

**MUST** — Open a pull request carrying the progress log when an implementation attempt is
abandoned, and say in the PR body what was attempted, where it broke, and what the next attempt
should do differently. **MUST NOT** — Delete the branch or the log. The failure is the
deliverable of a failed attempt.

## Phase 1: preparation

Establish the problem and a scope-limited plan name by questioning the human, then create the
working artifacts. Document the goals and decisions that arise while naming and limiting scope.

Order matters — the branch and directory are named after the plan, so the name comes first:

1. Agree the problem statement and the plan name with the human.
2. Create the planning branch, named for the plan number and problem, e.g. `001-create-test-vm`.
   See [Not on main branch](./WORKFLOW.md#not-on-main-branch) and
   [Up to date with main](./WORKFLOW.md#up-to-date-with-main) — branch from a current `main`.
3. Create `docs/plans/{plan-name}/` and the plan document from the template.
4. Commit.

Preparation is complete only when the plan exists with at least one goal, any initial research
or experiments have returned results, and preflight passed.

## Phase 2: ideation and exploration

- clarify the goals through the [grill-me loop](#interaction-the-grill-me-loop);
- convert claims into evidence-backed facts;
- search the codebase and the relevant documentation;
- investigate libraries, tools, and patterns that could shrink or reshape the plan;
- actively search for alternative solutions, third-party tooling included;
- run focused experiments on the important findings; and
- record positive, negative, failed, and abandoned results alike.

### Present every material alternative

**MUST** — Put every alternative that could materially affect the design to the human, who
accepts it or rejects it with a recorded rationale.

### No Execution Plan yet

**MUST NOT** — Write the `Execution Plan` section during this phase.

Exploration is complete only when all of the following hold:

- every goal has a recorded cheapest-passing-interpretation entry the human has accepted;
- the scope covers one problem;
- the alternatives search is recorded as a list of candidates, each accepted or rejected with
  evidence, and the human has confirmed the list is complete enough;
- no unresolved claim is being treated as fact; and
- the open-questions list is empty or every remaining item has been explicitly closed by the
  human.

## Phase 3: plan creation

Build the plan conservatively. Present one milestone at a time — its steps and its verification
test — then pause for the human to challenge or change it before moving on. Keep questioning
until you share an understanding of it.

If the human or your own investigation turns up an unknown, return to
[Phase 2](#phase-2-ideation-and-exploration).

The plan is complete only when every step, boundary, dependency, assumption, and verification
method is explicit enough that an implementing agent cannot reasonably read a different intent
into it.

## Completion

### Commit everything before proposing the exit

**MUST** — Ensure the plan and every supporting artifact — research, experiments, failed
attempts included — are committed on the planning branch.

### Ask before pushing

**MUST** — Ask the human for permission to push the branch and open a pull request, once the
plan is complete and committed. **MUST NOT** — Push, or open a PR, before they agree.

### Open the PR on approval

**MUST** — Push the branch and open the pull request when the human approves. The PR body
states the problem, the goals, and why this plan solves them, and links the plan document; it
**MUST NOT** merely restate the diff. See
[Pre-Review Content Checks](./CODE_REVIEW.md#2-pre-review-content-checks) — a PR that describes
only WHAT changed is rejected on sight.

### Do not implement

**MUST NOT** — Begin implementation. Implementation is a separate activity with its own branch,
started deliberately by the human.

---

See [`PLAN_TEMPLATE.md`](./PLAN_TEMPLATE.md) for the plan skeleton this document mandates.

See [`CODE_REVIEW.md`](./CODE_REVIEW.md) for how the resulting pull request is reviewed.
