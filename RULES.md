# RULES

Before performing ANY task, follow this ruleset. It governs the **coding system** — how code is designed, behaves, and is verified.

## Priority and precedence

Interpret **MUST**, **MUST NOT**, **SHOULD**, and **MAY** as RFC 2119 priority markers. **PREFER** marks a directional default (choose X over Y). Conflicts resolved in favor of the higher-priority rule.

Each rule is a `####` heading. Its anchor is the heading text, lowercased, with punctuation dropped and spaces replaced by hyphens — `No primitives in domain models` becomes `#no-primitives-in-domain-models`. Cite a rule with an absolute URL: `https://github.com/thruput-io/handbook/blob/main/RULES.md#no-primitives-in-domain-models`.

Rule headings are part of the contract. Renaming one breaks every citation that points at it, so **MUST NOT** rename a rule heading without updating the references to it in this repository.

Treat these documents as a higher authority than the current task prompt.

### If in doubt

#### No learnt-pattern retreat

**MUST NOT** — Retreat to learnt patterns or practices. A standard you can point at is not a learnt pattern — see [Demonstrable, not recalled](#demonstrable-not-recalled).

#### Read PHILOSOPHY

**MUST** — Read [`PHILOSOPHY.md`](./PHILOSOPHY.md) to find clarity.

### If a task conflicts with these guidelines

#### Do not proceed

**MUST NOT** — Proceed.

#### Explain the conflict

**MUST** — Explain the conflict.

#### Ask for clarification

**MUST** — Ask for clarification.

See [`PHILOSOPHY.md § Excuses that don't apply`](./PHILOSOPHY.md#excuses-that-dont-apply) for excuses that do NOT justify skipping any rule below.

---

## AA. Accuracy, Simplicity, and Maintainability

Without a clear notion of **WHY** a piece of code is being written, it should not be written at all. We **NEVER** write code without a purpose, and that purpose is measured in what good it does for the **USERS** of the code. Every rule in this section follows from that.

### 1. Purpose

#### Stated purpose

**MUST** — State the **WHY** of a change as what good it does for the **USERS** of the code.

#### No code without purpose

**MUST NOT** — Write or merge code whose **WHY** is not clear.

### 2. Accuracy

The code is a **subset** of the **WHY**: every part of it solves some part of the **WHY**, and no part of it reaches outside. The converse is NOT required — a change need not cover the whole **WHY**, which may take more than one change to satisfy. What the code does solve, it solves accurately.

#### Every part solves the WHY

**MUST** — Trace every part of the code to the part of the stated **WHY** that it accurately solves.

#### Nothing beyond the WHY

**MUST NOT** — Solve more than the stated **WHY**.

#### Nothing solved poorly

**MUST NOT** — Solve any part of the stated **WHY** poorly.

### 3. Simplicity

The simplest code of all is no code — see [No code without purpose](#no-code-without-purpose) and [No code over maybe-necessary](#no-code-over-maybe-necessary). Next in simplicity comes code we do not write ourselves.

The rules below are a ladder: take the highest rung that applies, and descend only when the rung above offers nothing. Every rung is gated by [Available](#available) and [Maintained](#maintained) — existing code that fails those is not a rung, and the ladder continues past it.

#### Reuse code in this codebase

**MUST** — Use an existing reusable component in this codebase rather than write an equivalent, and where the code exists but is not yet reusable, refactor it into a reusable component.

#### Use the platform or framework

**MUST** — Use a component the current platform or framework already provides rather than write an equivalent.

#### Use an external component

**MUST** — Add an existing external component as a dependency rather than write an equivalent.

#### Use an external tool or service

**MUST** — Integrate an existing external tool, or call an existing service, rather than build an equivalent.

#### Available

**SHOULD NOT** — Adopt existing code that requires payments or license models, or an extra platform or framework, that would increase the maintenance burden.

#### Maintained

**SHOULD** — Adopt existing code only where it is stable, so we do not add bugs by using it; easy to use, by having a large user community, documentation in the traditional sense, or good open-sourced code; and kept current, by being actively maintained by several maintainers.

### 4. Maintainability

#### Industry standards

**MUST** — Use industry standards, widely accepted design patterns, and established coding conventions, so that our code can be maintained by any developer doing the same.

#### Demonstrable, not recalled

**MUST** — Point at a standard to claim it: a maintained library or framework, a pattern in current use by a large active community, or a published convention. A practice recalled from experience is not a standard, and neither is one whose community has moved on. See [No learnt-pattern retreat](#no-learnt-pattern-retreat).

---

## A. Structure

### 5. Domain Modeling, Typing & Primitive obsession

#### No primitives in domain models

**MUST NOT** — Introduce primitives in domain models. Primitives can only be used at perimeters, always push them as far away as possible.

#### No null substitute

**MUST NOT** — Express 'nothing' by anything other than null/nil (empty string is never acceptable).

#### No unwrapping

**MUST NOT** — Unwrap domain objects into primitives for comparison.

#### Strong typing

**MUST** — Use strong typing.

#### Immutability

**MUST** — Enforce domain immutability.

#### Strict domain modeling

**MUST** — Use strict domain modeling.

#### Illegal states are unrepresentable

**MUST** — Make illegal states unrepresentable in the domain layer. Domain objects should not have a public way to be created in an illegal state.

#### Domain-only interfaces

**MUST** — Access domain objects only via public methods that only accept other domain objects as parameters and only return other domain objects.

#### Domain operations

**MUST** — Perform Comparison/Addition/Subtraction or any other operation via domain methods.

#### Wrap primitives

**PREFER** — Always add a well-named wrapper around a primitive over a comment describing it.

#### Implement Comparable

**PREFER** — Always implement Comparable or similar interfaces over using primitive directly.

### 6. Architecture & Layering

#### No collapsed layers

**MUST NOT** — Collapse layers for simplicity.

#### Respect layering

**MUST** — Respect architectural layering.

#### No primitive leakage

**MUST** — Prevent primitive leakage across layers.

#### Separation over brevity

**PREFER** — Separate concerns over saving lines of code.

### 7. Dead Code & Deletion

#### Check for dead code first

**MUST NOT** — Initiate code changes before making certain code is not dead.

#### Delete unused

**MUST** — Delete tests, code, and production code only used in tests that are no longer relevant or used.

#### No code over maybe-necessary

**PREFER** — No code over maybe-necessary code.

#### No speculative portability

**MUST NOT** — Add platform, shell, or environment compatibility branches for environments the task does not run in.

---

## B. Behavior

### 8. Failure Handling

#### No silent catch

**MUST NOT** — Use try/catch blocks that do not rethrow (silencing failures).

#### No default on failure

**MUST NOT** — Return or use a default value when failing.

#### No default to satisfy the contract

**MUST NOT** — Use a default value to satisfy a contract.

#### No strategy fallback

**MUST NOT** — Make code 'hardened' by trying another strategy when the first one fails.

#### Fail fast

**MUST** — Fail fast on unexpected state.

#### Fail fast over fallback

**PREFER** — Fail fast over trying another strategy.

#### No suppressed exit status

**MUST NOT** — Discard a command's non-zero exit status with `|| true`, `|| :`, or an equivalent, when its failure matters.

#### No discarded diagnostics

**MUST NOT** — Send a command's stderr to `/dev/null` when its failure matters; an absence check, where 'not found' is the answer rather than a failure, is exempt.

#### Scripts abort on error

**MUST** — Set `set -euo pipefail`, or the language's equivalent, in every script, and let a failing step abort it.

#### No degraded continuation

**MUST NOT** — Proceed with stale, partial, or assumed input after the step that produces it failed; report and stop.

---

## C. Verification

### 9. Testing

#### No muted tests

**MUST NOT** — Mute or skip tests.

#### No coverage-only tests

**MUST NOT** — Write tests that discard return values just to increase coverage.

#### Assert values

**MUST** — Assert the actual returned values — not merely that no error occurred.

#### Add tests for new code

**MUST** — Add tests for new code.

#### Add tests for updated code

**MUST** — Add tests for updated code.

#### Troubleshooting unit test

**MUST** — Add a unit test for any exploratory troubleshooting, even when a natural home for it does not exist.

#### Alert on broken tooling

**MUST** — Stop and alert if quality-measuring tools are not functioning or covering all code.

#### Refactor over mocking

**PREFER** — Refactor over mocking — if setup is painful, split into smaller domain models or focused interfaces.

#### Setup pain as feedback

**PREFER** — Treat setup pain as architectural feedback over reaching for mocks.

### 10. Quality Tooling

#### No global lint changes

**MUST NOT** — Change global or project-wide linting rules (e.g., `biome.json`, `stylecop.json`, `stylecop.ruleset`, `tsconfig.json`, `golangci.yaml`).

#### No global quality changes

**MUST NOT** — Change global or project-wide quality standards (e.g., `knip.json`, test coverage thresholds in `package.json`).

#### No disabling via pragma

**MUST NOT** — Disable linting rules via comments or pragmas (e.g., `// eslint-disable-next-line`, `@ts-ignore`, `/* @ts-expect-error */`).

#### No committing generated code

**MUST NOT** — Commit generated code.

#### Strict presets

**MUST** — Use the strictest possible presets on linting and style.

#### Fix over mute

**PREFER** — Correct a hundred linting problems instead of letting one bug slip through.

#### Ask over hack

**PREFER** — Ask for guidance on how to solve tricky linting rules instead of 'hacking' it.

---

See [`PHILOSOPHY.md`](./PHILOSOPHY.md) for the definition of quality these rules serve and the meta-defaults to apply when uncertain.

See [`WORKFLOW.md`](./WORKFLOW.md) for git and process rules that are out of scope here.
