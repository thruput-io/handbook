# {NNN} — {Plan name}

The skeleton mandated by [`PLANNING.md`](./PLANNING.md#plan-format). Copy it to
`docs/plans/{plan-name}/{NNN}-{plan-name}.md` in the target project and fill it in. Delete this
paragraph and replace every `{placeholder}`.

|                |                                               |
|----------------|-----------------------------------------------|
| Plan           | `docs/plans/{plan-name}/{NNN}-{plan-name}.md` |
| Branch         | `{NNN}-{plan-name}`                           |
| Started        | {YYYY-MM-DD}                                  |
| Supersedes     | {link to the previous numbered plan, or `—`}  |
| ADRs consulted | {list, or `none found`}                       |
| ADRs added     | {list, or `—`}                                |
| Status         | draft \| complete                             |

## Implementing Agent Instructions

Read this section first, and in full, before touching any code.

**Read before starting.**
[`RULES.md`](https://github.com/thruput-io/handbook/blob/main/RULES.md),
[`PHILOSOPHY.md`](https://github.com/thruput-io/handbook/blob/main/PHILOSOPHY.md),
[`WORKFLOW.md`](https://github.com/thruput-io/handbook/blob/main/WORKFLOW.md), and this plan end
to end. They outrank this plan; raise any conflict with the human instead of resolving it
yourself.

**Scope.** Implement exactly the milestones in [Execution Plan](#execution-plan), in order.
Anything not in this plan is out of scope — stop and ask rather than extending it.

**Definition of done.** Implementation is complete when every milestone's verification test
passes, `{the all-tests command}` reports success, and every goal in [Goals](#goals) is
delivered per the [Goal coverage](#goal-coverage) table.

**Verification.** Run `{the all-tests command}` — it lives at `{path}`. Do not treat a milestone
as done on inspection alone.

### Progress log

Before the first change, open
`docs/plans/{plan-name}/progress/{NNN}-attempt-{n}-{YYYY-MM-DD}.md` from
[`PLAN_IMPLEMENTATION_LOG.md`](https://github.com/thruput-io/handbook/blob/main/PLAN_IMPLEMENTATION_LOG.md)
and follow the rules stated in it. Opening it freezes this plan.

## Background

{Why this problem exists and what is happening today. Enough context that someone who was not in
the planning session understands the situation.}

### Goals

Prioritized and testable. Each states intent, not implementation steps.

1. {Goal}
2. {Goal}

#### Cheapest passing interpretation

For each goal: the cheapest implementation that would technically satisfy the wording while
missing the intent, and how the wording rules it out.

| Goal | Cheapest way to "pass" while missing the point | How the goal excludes it | Accepted by |
|---|---|---|---|
| 1 | {…} | {…} | [D{n}](#discussions) |

### Non-goals

Deliberately excluded from this plan.

- {Non-goal, and why it is out of scope}

## Summary

{Short prose: how the goals will be achieved.}

## Assumptions, risks and preconditions

| Assumption or risk | How it was tested | Result | If it turns out false |
|---|---|---|---|
| {…} | {tracer-bullet test path, or "untested"} | {…} | {…} |

**Preconditions.** {What must already be true before implementation starts — access, running
services, merged dependencies, tooling.}

## References

### Tracer-bullet tests

| Question | Test | Outcome |
|---|---|---|
| {…} | `{test-context}/exploratory/{plan-name}/{test}` | confirmed \| disproved |

### Research

| Question | Short answer | Evidence | Report |
|---|---|---|---|
| {…} | {…} | {…} | `research/{report-name}/` |

Negative findings and abandoned approaches belong here too, not only the successful ones.

### Rejected alternatives

| Alternative | Evidence gathered | Why rejected | Decision |
|---|---|---|---|
| {…} | {…} | {…} | [D{n}](#discussions) |

## Discussions

The decision register: one row per non-trivial decision, in the order the decisions were taken.
ADR conflicts found during preflight, and every ADR added during planning, are rows here too.

`Question` and `Answer` quote the exchange verbatim — the question exactly as it was put to the
human, and their reply in their own words. A paraphrase, a summary, or "agreed" is not a record.
Where the call was the agent's, `Decided by` says so and `Answer` quotes the human's approval of
it.

| # | Decision | Question put to the human | Answer (verbatim) | Decided by | Rationale | Date |
|---|---|---|---|---|---|---|
| D1 | {what was decided} | "{the question, as asked}" | "{their reply, in their words}" | human \| agent, human approved | {why this, and what it rules out} | {YYYY-MM-DD} |

## Open questions

Empty at completion, or every remaining item explicitly closed by the human. A closure is a
decision: it gets a [Discussions](#discussions) row quoting the question and the human's answer,
and the item links to it.

- [ ] {Question}
- [x] {Question} — closed by the human, [D{n}](#discussions)

## Execution Plan

### Goal coverage

| Goal | Delivered by |
|---|---|
| 1 | M1, M2 |

### Running all tests

`{command}` — {where it lives; whether it exists already or milestone M1 creates it}.

### Milestone M1 — {name}

**Delivers:** {goal(s), whole or part}

**Steps**

1. {Step}

**Verification:** {named, human-readable test — what is run and what result proves the
milestone}

### Milestone M2 — {name}

…
