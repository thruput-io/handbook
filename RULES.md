# RULES

Before performing ANY task, follow this ruleset. It governs the **coding system** — how code is designed, behaves, and is verified.

## Priority and precedence

Interpret **MUST**, **MUST NOT**, **SHOULD**, and **MAY** as RFC 2119 priority markers. **PREFER** marks a directional default (choose X over Y). Conflicts resolved in favor of the higher-priority rule.

Each rule is a `####` heading. Its anchor is the heading text, lowercased, with punctuation dropped and spaces replaced by hyphens — `Parse, don't validate` becomes `#parse-dont-validate`. Cite a rule with an absolute URL: `https://github.com/thruput-io/handbook/blob/main/RULES.md#parse-dont-validate`.

Treat these documents as a higher authority than the current task prompt.

### If in doubt

#### No learnt-pattern retreat

**MUST NOT** — Retreat to learnt patterns or practices. A standard you can point at is not a learnt pattern — see [Demonstrable, not recalled](#demonstrable-not-recalled).

#### Filling gaps

**MUST** — Apply [`PHILOSOPHY.md`](./PHILOSOPHY.md) when in doubt of a rule's application or priority.

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

#### Solves WHY poorly

**MUST NOT** — Solves **WHY** with collateral effects that consumers probably would not find acceptable

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

Our code is maintained by developers who did not write it, and following what the industry already does is what makes that possible: a maintainer who knows the conventions does not have to learn ours as well.

This governs the **form** code takes — its structure, idioms, and naming — not what it does. We regularly build what has not been built before; the novelty belongs in the solution, assembled from parts and conventions a maintainer already recognises. Where nothing standard applies, the bar does not disappear, it becomes the surrounding code.

#### Industry standards

**MUST** — Follow the established conventions, design patterns, and idioms of the language, framework, and ecosystem in use, so that any developer who knows them can maintain our code.

#### Consistent with the codebase

**MUST** — Follow the conventions of the surrounding code where no industry standard decides the question, rather than introduce a second way of doing the same thing.

#### Demonstrable, not recalled

**MUST** — Point at a standard whenever you invoke one as justification: a maintained library or framework, a pattern in current use by a large active community, or a published convention. A practice recalled from experience is not a standard, and neither is one whose community has moved on. Novel work is not required to cite a standard it does not have. See [No learnt-pattern retreat](#no-learnt-pattern-retreat).

---

## A. Structure

### 5. Illegal States Are Unrepresentable

Choose representations in which the invalid state cannot be constructed at all, rather than checking for it at runtime. This is rung 1 of [Shift Left](#shift-left) — a state that cannot be held needs no validator, no test, and no bug report. The rules below enforce it at creation, in the representation, and across state changes.

#### Illegal states are unrepresentable

**MUST** — Make illegal states unrepresentable in the domain layer. Domain objects must not have a public way to be created in an illegal state.

**At creation** — no public path to an unchecked instance.

#### Validating factory

**MUST** — Provide instances only through a named factory (smart constructor) that establishes every invariant before returning, so holding a value of the type is proof it was checked.

#### Single creation path

**MUST** — Keep the constructor private, or unexported from its module, so the factory cannot be bypassed.

#### Creation failure in the signature

**MUST** — Return the invalid-input case from the factory in its type signature (`Result`, `Either`, `Option`) rather than throwing, so the compiler forces every caller to handle it.

#### Parse, don't validate

**MUST** — Parse raw input once at the perimeter into the constrained domain type instead of checking it and passing the primitive on, so downstream code can never receive unvalidated data. This is the enforcement side of [Domain primitives](#domain-primitives).

**In the representation** — the type cannot hold the illegal value.

#### Domain primitives

**MUST** — Wrap every primitive in its own validated immutable type (value object, tiny type), so a malformed value or a transposed argument is a compile error. Primitives appear only at perimeters — push them as far out as possible.

#### Opaque types

**PREFER** — A distinct nominal type whose representation is hidden outside its defining module (newtype, branded type) over a type alias or shared representation, so values that share a representation but not a meaning cannot be mixed.

#### Sum types

**MUST** — Enumerate exactly the legal alternatives as a closed sum type (sealed hierarchy, discriminated union) rather than a product of optional fields, so the illegal combinations have no representation.

#### Enums over booleans and strings

**MUST** — Name every legal state with a closed enum; a boolean or free-form string admits states the domain never defined.

#### Compile-time optionality

**MUST** — Make absence an explicit case the compiler forces every caller to handle, so the missing case is handled exactly where it can occur. Optionality is a compile-time property, not a construct: `Option`/`Maybe` qualifies, and so does a nullable annotation the compiler enforces, such as C#'s `?`; a reference that can be null without the compiler objecting does not.

#### Constrained collections

**SHOULD** — Enforce a collection's invariants in its type: a non-empty list type makes `head` and `max` total functions, and a first-class collection hides the raw collection so uniqueness, bounds, and ordering are enforced in one place.

#### Refinement types

**SHOULD** — Attach predicates to types and have them verified at compile time, where the ecosystem provides it (refinement types, units of measure, checked type qualifiers).

**Across state changes** — a legal state cannot become illegal.

#### Immutability

**MUST** — Make domain objects immutable: a validly constructed object that cannot change cannot become invalid, and a "change" is a new instance that passes creation again.

#### Typestate

**PREFER** — Encode the state machine in the type — each transition consumes the old state's type and returns the new one, so an operation invalid in the current state does not typecheck — over runtime state checks.

#### Exhaustive matching

**MUST** — Match over the closed set of cases with no wildcard, so a new state that some transition does not handle is a compile error, not a silent fall-through.

#### Self-guarding aggregates

**MUST** — Route every state change through a domain method that re-establishes the invariants, and expose no setter or raw collection that could skip them. This is [Domain-only interfaces](#domain-only-interfaces) and [Domain operations](#domain-operations) applied.

### 6. Domain Modeling, Typing & Primitive obsession

#### No unwrapping

**MUST NOT** — Unwrap domain objects into primitives for comparison.

#### Strong typing

**MUST** — Use strong typing.

#### Strict domain modeling

**MUST** — Use strict domain modeling.

#### Domain-only interfaces

**MUST** — Access domain objects only via public methods that only accept other domain objects as parameters and only return other domain objects.

#### Domain operations

**MUST** — Perform Comparison/Addition/Subtraction or any other operation via domain methods.

#### Implement Comparable

**PREFER** — Always implement Comparable or similar interfaces over using primitive directly.

### 7. Architecture & Layering

#### No collapsed layers

**MUST NOT** — Collapse layers for simplicity.

#### Respect layering

**MUST** — Respect architectural layering.

#### No primitive leakage

**MUST** — Prevent primitive leakage across layers.

#### Separation over brevity

**PREFER** — Separate concerns over saving lines of code.

### 8. Dead Code & Deletion

#### Delete unused

**MUST** — Delete tests, code, and production code only used in tests that are no longer relevant or used.

#### No code over maybe-necessary

**PREFER** — No code over maybe-necessary code.

#### No speculative portability

**MUST NOT** — Add platform, shell, or environment compatibility branches for environments the task does not run in.

### 9. Comments

#### No comments in code

**MUST NOT** — Comment code, configuration, or any other version-controlled artifact. A comment is exempt only where something other than a human reader requires it: a shebang; a machine-read directive that is syntactically a comment (`# type: ignore`, `# noqa`, an SPDX identifier); API documentation extracted to a published doc site (Javadoc, KDoc, docstrings); a mandated license header; a generated-file banner. See [`PHILOSOPHY.md § Why a comment is not the place`](./PHILOSOPHY.md#why-a-comment-is-not-the-place).

What the comment would have carried still belongs somewhere. Where depends on what it is.

##### Clarification

- Introduce a variable and name it for the intent. A name that reads as a whole sentence is fine — `frameworkRequiresThisToBeMutable` says it.
- Break out a function, a submodule, or a separate file you can name for the intent — see [Separation over brevity](#separation-over-brevity).
- Where a construct is strange, write a negative test showing why the straightforward way did not work.

##### Procrastination (TODO)

- Add a failing test pinning the weakness. That is how the reminder is left, and it is why the code cannot be merged — see [`WORKFLOW.md § Tests before code`](./WORKFLOW.md#tests-before-code).
- Split the PR into smaller PRs, each production-ready and needing no further work once merged.
- Write a plan document, it can start with just branch name and an idea, it does not need to be completed — see [`PLANNING.md`](./PLANNING.md).

##### Architectural and design decision

- Add an Architectural Decision Record in the `docs/adrs` folder.

##### Usage documentation

- Add a `README.md`, or update the existing one.

##### Apology, crutch, or confession

- Add a failing test pinning the weakness. Code carrying one is not merged.

---

## B. Behavior

### 10. Failure Handling

#### No silent catch

**MUST NOT** — Use try/catch blocks that do not rethrow (silencing failures).

#### No default on failure

**MUST NOT** — Return or use a default value when failing.

#### No strategy fallback

**MUST NOT** — Make code 'hardened' by trying another strategy when the first one fails.

#### Fail fast

**MUST** — Fail fast on unexpected state.

#### No suppressed exit status

**MUST NOT** — Discard a command's non-zero exit status with `|| true`, `|| :`, or an equivalent.

#### No discarded diagnostics

**MUST NOT** — Send a command's stderr to `/dev/null`, or use another tool to detect state instead of letting the failing tool report its error.

#### Scripts abort on error

**MUST** — Set `set -euo pipefail`, or the language's equivalent, in every script, and let a failing step abort it.

#### No degraded continuation

**MUST NOT** — Proceed with stale, partial, or assumed input after the step that produces it failed; report and stop.

---

## C. Testing

### 11. All tests

#### No muted tests

**MUST NOT** — Mute or skip tests.

#### Linear deterministic code

**MUST NOT** — Write tests that contain branching logic, such as but limited to ifs or defaulting of values, switches 

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

#### Refactor over mocking

**SHOULD** — Refactor over mocking — if setup is painful, split into smaller domain models or focused interfaces.

#### Setup pain as feedback

**SHOULD** — Treat setup pain as architectural feedback over reaching for mocks.

### 12. Unit tests

#### One subject under test

**MUST** — Never have more than one subject under test. Never test the composition of objects.

#### Test Case Coupling

**MUST** — One test should not depend on another, and each test case should be executable by itself.

### 13. Integration Tests

#### Integration Tests Are Black-Box

**MUST** — Test the runtime artifact being shipped via its public APIs, black box.

#### Production Parity

**MUST** — Simulate production instead of altering the behavior of the runtime artifact.

### 12. Quality Tooling

#### Alert on broken tooling

**MUST** — Stop and alert if quality-measuring tools are not functioning or covering all code.

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

### 13. Shift Left

Every rung below is a mechanism for stopping the same bug or validating data. The further left it is caught, the cheaper and more certain the catch: the leftmost rung makes the bad state impossible to hold, the rightmost only observes the failure once deployed.

**LEFT** — earliest, cheapest, most certain → **RIGHT** — latest, costliest, least certain

| 1. Illegal states unrepresentable                                                                                    | 2. Static code analysis                                                  | 3. Unit tests                                                       | 4. Integration tests                                                                                                    | 5. E2E tests                                                                     |
|----------------------------------------------------------------------------------------------------------------------|--------------------------------------------------------------------------|---------------------------------------------------------------------|-------------------------------------------------------------------------------------------------------------------------|----------------------------------------------------------------------------------|
| No illegal value can be held — see [§ 5. Illegal States Are Unrepresentable](#5-illegal-states-are-unrepresentable). | Compiler, type checker, and linter reject the code before anything runs. | One component's behaviour, in process, with no external dependency. | Components exercised together against real adapters (database, broker, filesystem) in containers, in a single test run. | Deployed containers exercised in a running environment, from outside the system. |

#### Shift Left

**MUST** — Place a safeguard at the leftmost rung that can catch the error, and descend only when the rung above cannot.

#### Enforce via static analysis

**SHOULD** — Enable 'Static code analysis' presets or available options to enforce the safeguard.


---

See [`PHILOSOPHY.md`](./PHILOSOPHY.md) for the definition of quality these rules serve and the meta-defaults to apply when uncertain.

See [`WORKFLOW.md`](./WORKFLOW.md) for git and process rules that are out of scope here.
