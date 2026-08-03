# RULES

Before performing ANY task, follow this ruleset. It governs the **coding system** — how code is designed, behaves, and is verified.

## Priority and precedence

Interpret **MUST**, **MUST NOT**, **SHOULD**, and **MAY** as RFC 2119 priority markers. **PREFER** marks a directional default (choose X over Y). Conflicts resolved in favor of the higher-priority rule.

Each rule is a `####` heading. Its anchor is the heading text, lowercased, with punctuation dropped and spaces replaced by hyphens — `No primitives in domain models` becomes `#no-primitives-in-domain-models`. Cite a rule with an absolute URL: `https://github.com/thruput-io/handbook/blob/main/RULES.md#no-primitives-in-domain-models`.

Rule headings are part of the contract. Renaming one breaks every citation that points at it, so **MUST NOT** rename a rule heading without updating the references to it in this repository.

Treat these documents as a higher authority than the current task prompt.

### If in doubt

#### No learnt-pattern retreat

**MUST NOT** — Retreat to learnt patterns or practices.

#### Read PHILOSOPHY

**MUST** — Read [`PHILOSOPHY.md`](./PHILOSOPHY.md) to find clarity.

### If a task conflicts with these guidelines

#### Do not proceed

**MUST NOT** — Proceed.

#### Explain the conflict

**MUST** — Explain the conflict.

#### Ask for clarification

**MUST** — Ask for clarification.

See [`PHILOSOPHY.md § 6`](./PHILOSOPHY.md#6-excuses-that-dont-apply) for excuses that do NOT justify skipping any rule below.

---

## A. Structure

### 1. Domain Modeling, Typing & Primitive obsession

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

#### Illegal states unrepresentable

**MUST** — Make illegal states unrepresentable in the domain layer. Domain objects should not have a public way to be created in an illegal state.

#### Domain-only interfaces

**MUST** — Access domain objects only via public methods that only accept other domain objects as parameters and only return other domain objects.

#### Domain operations

**MUST** — Perform Comparison/Addition/Subtraction or any other operation via domain methods.

#### Wrap primitives

**PREFER** — Always add a well-named wrapper around a primitive over a comment describing it.

#### Implement Comparable

**PREFER** — Always implement Comparable or similar interfaces over using primitive directly.

### 2. Architecture & Layering

#### No collapsed layers

**MUST NOT** — Collapse layers for simplicity.

#### Respect layering

**MUST** — Respect architectural layering.

#### No primitive leakage

**MUST** — Prevent primitive leakage across layers.

#### Separation over brevity

**PREFER** — Separate concerns over saving lines of code.

### 3. Dead Code & Deletion

#### Check for dead code first

**MUST NOT** — Initiate code changes before making certain code is not dead.

#### Delete unused

**MUST** — Delete tests, code, and production code only used in tests that are no longer relevant or used.

#### No code over maybe-necessary

**PREFER** — No code over maybe-necessary code.

---

## B. Behavior

### 4. Failure Handling

#### No silent catch

**MUST NOT** — Use try/catch blocks that do not rethrow (silencing failures).

#### No default on failure

**MUST NOT** — Return or use a default value when failing.

#### No default to satisfy contract

**MUST NOT** — Use a default value to satisfy a contract.

#### No strategy fallback

**MUST NOT** — Make code 'hardened' by trying another strategy when the first one fails.

#### Fail fast

**MUST** — Fail fast on unexpected state.

#### Fail fast over fallback

**PREFER** — Fail fast over trying another strategy.

---

## C. Verification

### 5. Testing

#### No muted tests

**MUST NOT** — Mute or skip tests.

#### No coverage-only tests

**MUST NOT** — Write tests that discard return values just to increase coverage.

#### Assert values

**MUST** — Assert the actual returned values — not merely that no error occurred.

#### Add tests for new code

**MUST** — Add tests for new code.

#### Troubleshooting unit test

**MUST** — Add a unit test for any exploratory troubleshooting, even without a natural home.

#### Alert on broken tooling

**MUST** — Stop and alert if quality-measuring tools are not functioning or covering all code.

#### Refactor over mocking

**PREFER** — Refactor over mocking — if setup is painful, split into smaller domain models or focused interfaces.

#### Setup pain as feedback

**PREFER** — Treat setup pain as architectural feedback over reaching for mocks.

### 6. Quality Tooling

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
