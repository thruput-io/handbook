# PHILOSOPHY

The rules in [`RULES.md`](./RULES.md) exist to serve the definition of quality below. This file also captures the meta-defaults to apply when a specific rule doesn't decide the question.

Anchors follow the same convention as [`RULES.md`](./RULES.md#priority-and-precedence): the heading text, lowercased, punctuation dropped, spaces replaced by hyphens. Cite a principle with an absolute URL: `https://github.com/thruput-io/handbook/blob/main/PHILOSOPHY.md#correctness`.

## A. Meta-defaults

### 1. When uncertain

Default to:

#### Strict domain modeling over ad-hoc

**PREFER** — Strict domain modeling over ad-hoc structures. See [Strict domain modeling](./RULES.md#strict-domain-modeling).

#### Stronger typing over weaker

**PREFER** — Stronger typing over weaker typing. See [Strong typing](./RULES.md#strong-typing).

#### Architecture over brevity

**PREFER** — Architectural discipline over brevity. See [Separation over brevity](./RULES.md#separation-over-brevity).

## B. Quality

### 2. What software quality is

#### Highest priority

**MUST** — Software quality is ALWAYS the highest priority.

#### No quality tradeoff

**MUST NOT** — There is NO SITUATION that justifies lowering quality in favor of other goals.

#### Quality enables goals

**MUST** — ALL OTHER OBJECTIVES will be harder to achieve if quality is lowered.

#### No tradeoff for faster development

**MUST NOT** — Lower quality to enable faster development.

#### No tradeoff for higher performance

**MUST NOT** — Lower quality to enable higher performance.

#### No tradeoff for new features

**MUST NOT** — Lower quality to enable new features.

### 3. The vocabulary of quality

#### The attributes

These are the terms to use when arguing about quality: they name the axes a change can be good or
bad along, so a review can say *which* kind of worse something is. They are descriptive, not
enforceable — citing an attribute characterizes a problem, it does not settle it. The requirement
being violated **MUST** come from [`RULES.md`](./RULES.md); if no rule decides the question, the
meta-defaults in [When uncertain](#1-when-uncertain) do.

The attributes:

- [Correctness](#correctness)
- [Maintainability](#maintainability)
- [Readability](#readability)
- [Testability](#testability)
- [Simplicity](#simplicity)
- [True test coverage](#true-test-coverage)
- [Ease of doing the right thing](#ease-of-doing-the-right-thing)
- [Guardrails against doing the wrong thing](#guardrails-against-doing-the-wrong-thing)
- [Automation](#automation)
- [Currency of tools and libraries](#currency-of-tools-and-libraries)

#### Correctness

The software does what our users want it to do.

#### Maintainability

Changing one behaviour requires understanding and touching only the code that owns it.

#### Readability

A reader unfamiliar with the code can say what it does, and why, without asking its author.

#### Testability

Behaviour can be exercised in isolation, without standing up the network, the clock, or global state.

#### Simplicity

The design carries no structure that a present requirement does not demand.

#### True test coverage

Tests that fail when the behaviour breaks — as opposed to tests that merely execute the lines.

#### Ease of doing the right thing

The correct approach is also the path of least resistance for the next contributor.

#### Guardrails against doing the wrong thing

Types, tests, and tooling make the wrong approach fail early, rather than merely discouraging it.

#### Automation

The steps between a change and its verified deployment that run without a human.

#### Currency of tools and libraries

Currency of tools and libraries used, and the ease of keeping them current.

### 4. How quality is NOT measured

#### Non-measurement attributes

**MUST NOT** — Measure quality by any of the following:

- [Convenience](#convenience)
- [Cleverness](#cleverness)
- [Compactness](#compactness)
- [Performance](#performance)
- [Features](#features)

#### Convenience

Defaulting to the easiest or most convenient option.

#### Cleverness

Smartness or cleverness.

#### Compactness

Compactness.

#### Performance

Performance.

#### Features

Features.

### 5. How quality is achieved

#### Strictness over sloppiness

**PREFER** — Always striving for strictness over sloppiness.

#### Fail fast over fallbacks

**PREFER** — Failing fast over using fallbacks. See [Fail fast over fallback](./RULES.md#fail-fast-over-fallback).

#### Best practices and standards

**MUST** — Following best practices and standards.

#### Testable and tested

**MUST** — Making all our code testable and tested.

#### Illegal states unrepresentable

**MUST** — Making illegal states unrepresentable. See [Illegal states unrepresentable](./RULES.md#illegal-states-unrepresentable).

### 6. Excuses that don't apply

These principles apply even when it feels like they shouldn't. The following rationalizations are NOT valid grounds for skipping any rule in [`RULES.md`](./RULES.md) or any principle above:

#### Mock or test code

"It is just mock or test code that is not equally important, so I can disregard strictness."

#### Prototype

"This is just a prototype, I will add tests later."

#### Usually needed safeguards

"These safeguards are usually needed, so I will add them here too."

The fallacy is generalizing a habit onto a case that has not been shown to need it. Concretely:
appending `|| true` or `2>/dev/null` to a command whose failure matters; catching an exception only
to log it and continue; branching on the platform when the task fixes the platform; substituting a
default when an input is missing instead of stopping. Each one converts a loud, diagnosable failure
into a silent wrong answer, which is the opposite of
[Fail fast over fallbacks](#fail-fast-over-fallbacks). Add a safeguard when *this* path is shown to
need it, and say what showed it.

#### Standard over strict

"Since this way of doing stuff is standard, I will follow it instead of being strict."

#### Massive refactor

"Following these guidelines would require a massive refactor."

#### Mute warning

"Since I cannot find a way to avoid this code warning, I will mute it."

#### Codebase already ignores

"I can see guidelines are not followed in this codebase so it is not important I do."

---

See [`RULES.md`](./RULES.md) for the enforceable rules that operationalize this philosophy.

See [`WORKFLOW.md`](./WORKFLOW.md) for git and process rules.
