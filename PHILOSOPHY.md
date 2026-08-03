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

### 3. How quality is measured

#### Measurement attributes

**MUST** — Measure quality by the following attributes:

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

The code can be maintained over time.

#### Readability

The code is readable.

#### Testability

The code is testable.

#### Simplicity

The code is simple.

#### True test coverage

'True' test coverage.

#### Ease of doing the right thing

Ease of doing the right thing.

#### Guardrails against doing the wrong thing

Guardrails against doing the wrong thing.

#### Automation

Level of automation in development, testing, and deployment.

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

"Since these safeguards are usually needed, I will add them."

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
