# PHILOSOPHY

The rules in [`RULES.md`](./RULES.md) exist to serve the definition of quality below. This file also captures the meta-defaults to apply when a specific rule doesn't decide the question.

Each rule has a short human-readable heading and a stable HTML anchor id like `philosophy-measurement-correctness`. Cite a rule with an absolute URL: `https://github.com/thruput-io/handbook/blob/main/PHILOSOPHY.md#philosophy-measurement-correctness`.

## A. Meta-defaults

### 1. When uncertain

Default to:

#### Strict domain modeling over ad-hoc <a id="philosophy-uncertainty-strict-domain-modeling-over-ad-hoc"></a>

**PREFER** — Strict domain modeling over ad-hoc structures. See [Strict domain modeling](./RULES.md#structure-domain-modeling-strict-domain).

#### Stronger typing over weaker <a id="philosophy-uncertainty-stronger-typing-over-weaker-typing"></a>

**PREFER** — Stronger typing over weaker typing. See [Strong typing](./RULES.md#structure-domain-modeling-strong-typing).

#### Architecture over brevity <a id="philosophy-uncertainty-architecture-over-brevity"></a>

**PREFER** — Architectural discipline over brevity. See [Separation over brevity](./RULES.md#structure-architecture-separation-over-brevity).

## B. Quality

### 2. What software quality is

#### Highest priority <a id="philosophy-quality-highest-priority"></a>

**MUST** — Software quality is ALWAYS the highest priority.

#### No quality tradeoff <a id="philosophy-quality-no-quality-tradeoff"></a>

**MUST NOT** — There is NO SITUATION that justifies lowering quality in favor of other goals.

#### Quality enables goals <a id="philosophy-quality-quality-enables-goals"></a>

**MUST** — ALL OTHER OBJECTIVES will be harder to achieve if quality is lowered.

#### No tradeoff for faster development <a id="philosophy-quality-no-faster-development-tradeoff"></a>

**MUST NOT** — Lower quality to enable faster development.

#### No tradeoff for higher performance <a id="philosophy-quality-no-higher-performance-tradeoff"></a>

**MUST NOT** — Lower quality to enable higher performance.

#### No tradeoff for new features <a id="philosophy-quality-no-new-features-tradeoff"></a>

**MUST NOT** — Lower quality to enable new features.

### 3. How quality is measured

#### Measurement attributes <a id="philosophy-measurement-attributes"></a>

**MUST** — Measure quality by the following attributes:

- [Correctness](#philosophy-measurement-correctness)
- [Maintainability](#philosophy-measurement-maintainability)
- [Readability](#philosophy-measurement-readability)
- [Testability](#philosophy-measurement-testability)
- [Simplicity](#philosophy-measurement-simplicity)
- [True test coverage](#philosophy-measurement-true-test-coverage)
- [Ease of doing the right thing](#philosophy-measurement-ease-of-right)
- [Guardrails against doing the wrong thing](#philosophy-measurement-guardrails-against-wrong)
- [Automation](#philosophy-measurement-automation)
- [Currency of tools and libraries](#philosophy-measurement-currency)

#### Correctness <a id="philosophy-measurement-correctness"></a>

The software does what our users want it to do.

#### Maintainability <a id="philosophy-measurement-maintainability"></a>

The code can be maintained over time.

#### Readability <a id="philosophy-measurement-readability"></a>

The code is readable.

#### Testability <a id="philosophy-measurement-testability"></a>

The code is testable.

#### Simplicity <a id="philosophy-measurement-simplicity"></a>

The code is simple.

#### True test coverage <a id="philosophy-measurement-true-test-coverage"></a>

'True' test coverage.

#### Ease of doing the right thing <a id="philosophy-measurement-ease-of-right"></a>

Ease of doing the right thing.

#### Guardrails against doing the wrong thing <a id="philosophy-measurement-guardrails-against-wrong"></a>

Guardrails against doing the wrong thing.

#### Automation <a id="philosophy-measurement-automation"></a>

Level of automation in development, testing, and deployment.

#### Currency of tools and libraries <a id="philosophy-measurement-currency"></a>

Currency of tools and libraries used, and the ease of keeping them current.

### 4. How quality is NOT measured

#### Non-measurement attributes <a id="philosophy-non-measurement-attributes"></a>

**MUST NOT** — Measure quality by any of the following:

- [Convenience](#philosophy-non-measurement-convenience)
- [Cleverness](#philosophy-non-measurement-cleverness)
- [Compactness](#philosophy-non-measurement-compactness)
- [Performance](#philosophy-non-measurement-performance)
- [Features](#philosophy-non-measurement-features)

#### Convenience <a id="philosophy-non-measurement-convenience"></a>

Defaulting to the easiest or most convenient option.

#### Cleverness <a id="philosophy-non-measurement-cleverness"></a>

Smartness or cleverness.

#### Compactness <a id="philosophy-non-measurement-compactness"></a>

Compactness.

#### Performance <a id="philosophy-non-measurement-performance"></a>

Performance.

#### Features <a id="philosophy-non-measurement-features"></a>

Features.

### 5. How quality is achieved

#### Strictness over sloppiness <a id="philosophy-achievement-strictness-over-sloppiness"></a>

**PREFER** — Always striving for strictness over sloppiness.

#### Fail fast over fallbacks <a id="philosophy-achievement-fail-fast-over-fallbacks"></a>

**PREFER** — Failing fast over using fallbacks. See [Fail fast over fallback](./RULES.md#behavior-failure-handling-fail-fast-over-fallback).

#### Best practices and standards <a id="philosophy-achievement-best-practices-and-standards"></a>

**MUST** — Following best practices and standards.

#### Testable and tested <a id="philosophy-achievement-testable-and-tested"></a>

**MUST** — Making all our code testable and tested.

#### Illegal states unrepresentable <a id="philosophy-achievement-illegal-states-unrepresentable"></a>

**MUST** — Making illegal states unrepresentable. See [Illegal states unrepresentable](./RULES.md#structure-domain-modeling-illegal-states-unrepresentable).

### 6. Excuses that don't apply

These principles apply even when it feels like they shouldn't. The following rationalizations are NOT valid grounds for skipping any rule in [`RULES.md`](./RULES.md) or any principle above:

#### Mock or test code <a id="philosophy-excuses-mock-or-test-code"></a>

"It is just mock or test code that is not equally important, so I can disregard strictness."

#### Prototype <a id="philosophy-excuses-prototype"></a>

"This is just a prototype, I will add tests later."

#### Usually needed safeguards <a id="philosophy-excuses-usually-needed-safeguards"></a>

"Since these safeguards are usually needed, I will add them."

#### Standard over strict <a id="philosophy-excuses-standard-over-strict"></a>

"Since this way of doing stuff is standard, I will follow it instead of being strict."

#### Massive refactor <a id="philosophy-excuses-massive-refactor"></a>

"Following these guidelines would require a massive refactor."

#### Mute warning <a id="philosophy-excuses-mute-warning"></a>

"Since I cannot find a way to avoid this code warning, I will mute it."

#### Codebase already ignores <a id="philosophy-excuses-codebase-already-ignores"></a>

"I can see guidelines are not followed in this codebase so it is not important I do."

---

See [`RULES.md`](./RULES.md) for the enforceable rules that operationalize this philosophy.

See [`WORKFLOW.md`](./WORKFLOW.md) for git and process rules.
