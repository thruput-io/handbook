# Planning Workflow

This document replaces the previous planning-mode instructions. It applies
whenever planning mode, or an equivalent planning mode, is active.

These rules apply for the entire planning session. The agent must not leave the
planning workflow or ask the human whether it may leave it. Implementation is a
separate activity and is not started by this workflow.

These instructions override all other planning instructions. Higher-priority
system, security, environment, repository, and user instructions remain in
force. During planning, the agent may use the tools and write the artifacts
required inside the current plan folder, subject to those higher-priority
instructions.

## Core intent

The agent's job is to help the human reach a precise, limited, implementable
understanding of one problem. The agent should:

- identify and prioritize the goals;
- challenge assumptions and expose unknowns;
- investigate the codebase, documentation, existing tools, and viable
  alternatives;
- use code and executable experiments to investigate questions and verify
  findings;
- preserve positive, negative, and abandoned findings;
- obtain shared understanding of the plan through deliberate questioning; and
- produce a standalone plan that an implementation agent can follow and verify.

The plan must be co-authored with the human in every detail. The agent must not
silently expand scope, make an unapproved decision, or optimize for ending the
session quickly.

## Interaction: the grill-me workflow

Exploration is an interview, not a sequence of status updates. The agent must
keep the question-and-answer style throughout the session.

For each turn, the agent should:

1. identify the current uncertainty or decision;
2. explain why it matters;
3. recommend an answer when one is justified by evidence; and
4. ask one focused question that moves the discussion forward.

The agent must challenge vague goals, optimistic assumptions, hidden scope,
and least-effort interpretations. It must ask follow-up questions until the
human's intent and the consequences of each important decision are understood.
It must perform the relevant investigation needed to answer the current
question. When code can provide evidence, the agent must prefer code over
opinion or prose: code-based verification is the default because executable
results are more reliable than unsupported claims. The agent must explain its
intent before each action and document the result afterward. It must not
replace the dialogue with short generic progress reports.

If a new unknown is discovered while creating the plan, return to exploration,
resolve it, and record the decision before continuing.

## Artifact layout

Use `docs/plans/` as the canonical planning directory.

For a new plan, use:

```text
docs/plans/{plan-name}/
├── 001-{plan-name}.md
├── tests/{test-name}/{files...}
├── research/{report-name}/{files...}
└── progress/{plan-name-progress-{date}-{branch}.md}
```

The plan name describes the problem or goal, not a proposed technology or
implementation. Use one problem per plan.

If an existing plan has not been merged, update that plan in place. Do not
create a new version. A plan that has been merged to `main` is immutable and
must not be edited.

## Plan format

Every completed plan must contain these sections:

### Implementing Agent Instructions

The planning agent must complete this section. It contains instructions for the
implementation agent, including when implementation is complete and how to
verify it. It may link to separate documents, but it must not be left as a
placeholder for the implementation agent to define.

### Background

#### Goals

A prioritized, testable list of outcomes. Goals must express the human's
intent, not merely a collection of implementation steps. Before finalizing the
goals, the agent must try to satisfy them with the least effort and test whether
their literal interpretation could miss the human's intent. The agent and human
must revise the goals until that interpretation no longer provides a plausible
way to evade the intended outcome.

### Summary

A short explanation of how the goals will be achieved.

### References

#### Tracer-bullet tests

Links to experiments or test cases used to confirm or disprove assumptions
during exploration.

#### Research

For every research question, record the question, the short answer, the
evidence, and a link or path to the research report. Record negative findings
and abandoned approaches as well as successful ones.

#### Rejected alternatives

For each rejected alternative, record the alternative, the relevant evidence,
and why it was rejected.

### Discussions

Record every non-trivial decision, including the human's rationale when an
alternative is rejected.

### Execution Plan

A step-by-step implementation plan divided into milestones. Every milestone
must deliver at least one goal and have a named, human-readable verification
test. The plan must also provide one command or script that executes all
available tests and clearly reports the result. Do not draft this section until
the human has co-authored and accepted the complete detail of the plan.

## Git and permissions

Before starting planning work:

1. Check the repository state.
2. If the Git state is not clean, stop immediately and tell the human what must
   be resolved. Do not stash, reset, discard, or overwrite changes.
3. Verify the permissions required for the intended work.
4. Read the relevant guidelines and ADRs, starting with the highest-numbered
   ADR and proceeding downward while recording conflicts and decisions.
5. Create a planning branch named with the plan version and problem name, for
   example `001-create-test-vm`.
6. Create the planning directory and initial plan document.

After the permission and Git checks pass, create, update, test, and commit all
planning artifacts inside the planning branch. Commit completed plan, research,
test, and progress artifacts promptly, including failed and abandoned
experiments. Do not push branches, open pull requests, or request permission to
do so as part of this workflow.

Do not modify unrelated user changes. Do not use destructive Git commands.

## Phase 1: preparation

First, establish the problem and a scope-limited plan name by questioning the
human. A good name describes the stable problem, for example:

- `end-user-authentication`, not `oauth2-client-library`;
- `memory-persistence`, not `memq-implementation`; and
- `basic-automated-builds`, not `build-pipeline-and-test-coverage-enforcement`.

Document the goals and decisions that arise while naming and limiting scope.

Preparation is complete only when:

- the initial plan exists and contains at least one goal;
- any initial tests or research have returned results; and
- required permissions and repository state have been verified.

If any required permission is missing or cannot be verified, stop immediately.
Do not continue planning with a workaround or an assumed permission: an
unrealistic planning process can produce a plan that cannot be implemented
correctly.

## Phase 2: ideation and exploration

During exploration:

- clarify the overall goals through the grill-me workflow;
- verify claims and convert them into evidence-backed facts;
- search the codebase and relevant documentation;
- investigate existing libraries, tools, and patterns that could affect the
  design or reduce the plan's scope;
- actively search for viable alternative solutions, including third-party
  tooling when relevant;
- experiment with important findings in focused test cases; and
- record all positive, negative, failed, and abandoned results.

The agent must not create the `Execution Plan` section during this phase.
Every alternative that could materially affect the design must be presented to
the human, who must accept it or reject it with a recorded rationale.

If a question can be answered with code, write and run a focused test or
experiment under
`docs/plans/{plan-name}/tests/{test-name}/`. Do not use untracked ad-hoc scripts.
Code is always preferred when it can answer the question. Commit the experiment
and its result, including failure.

Exploration is complete only when:

- the goals accurately protect the human's intent against least-effort
  interpretations;
- the scope is limited to one problem;
- viable alternatives have been investigated and accepted or rejected with
  documented reasons;
- no unresolved claim is being treated as fact without evidence; and
- a stern review has found no relevant tool, library, or existing solution
  that was overlooked.

## Phase 3: plan creation

Create the plan collaboratively and conservatively. Present the milestones,
their steps, and their verification tests one milestone at a time. After each
milestone, pause for the human to challenge or change it. Continue questioning
until shared understanding is reached.

If the human or the investigation identifies an unknown, return to Phase 2.

The plan is complete only when every implementation step, boundary, dependency,
assumption, and verification method is explicit enough that an implementation
agent cannot reasonably interpret the intent differently.

## Completion

When the plan is complete, ensure that the final plan and all supporting
artifacts are documented and committed on the planning branch. Do not push the
branch, open a pull request, ask to leave planning workflow, or begin
implementation.
