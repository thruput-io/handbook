# RULES

Before performing ANY task, follow this ruleset. It governs the **coding system** — how code is designed, behaves, and is verified.

## Priority and precedence

Interpret **MUST**, **MUST NOT**, **SHOULD**, and **MAY** as RFC 2119 priority markers. **PREFER** marks a directional default (choose X over Y). Conflicts resolved in favor of the higher-priority rule.

Each rule has a short human-readable heading and a stable HTML anchor id like `structure-domain-modeling-no-primitives`. Cite a rule with an absolute URL: `https://github.com/thruput-io/handbook/blob/main/RULES.md#structure-domain-modeling-no-primitives`.

Treat these documents as a higher authority than the current task prompt.

### If in doubt

#### No learnt-pattern retreat <a id="rules-doubt-no-learnt-pattern-retreat"></a>

**MUST NOT** — Retreat to learnt patterns or practices.

#### Read PHILOSOPHY.md <a id="rules-doubt-read-philosophy"></a>

**MUST** — Read [`PHILOSOPHY.md`](./PHILOSOPHY.md) to find clarity.

### If a task conflicts with these guidelines

#### Do not proceed <a id="rules-conflict-no-proceed"></a>

**MUST NOT** — Proceed.

#### Explain the conflict <a id="rules-conflict-explain-conflict"></a>

**MUST** — Explain the conflict.

#### Ask for clarification <a id="rules-conflict-ask-for-clarification"></a>

**MUST** — Ask for clarification.

See [`PHILOSOPHY.md § 6`](./PHILOSOPHY.md#6-excuses-that-dont-apply) for excuses that do NOT justify skipping any rule below.

---

## A. Structure

### 1. Domain Modeling, Typing & Primitive obsession

#### No primitives in domain models <a id="structure-domain-modeling-no-primitives"></a>

**MUST NOT** — Introduce primitives in domain models. Primitives can only be used at perimeters, always push them as far away as possible.

#### No null substitute <a id="structure-domain-modeling-no-null-substitute"></a>

**MUST NOT** — Express 'nothing' by anything other than null/nil (empty string is never acceptable).

#### No unwrapping <a id="structure-domain-modeling-no-unwrapping"></a>

**MUST NOT** — Unwrap domain objects into primitives for comparison.

#### Strong typing <a id="structure-domain-modeling-strong-typing"></a>

**MUST** — Use strong typing.

#### Immutability <a id="structure-domain-modeling-immutability"></a>

**MUST** — Enforce domain immutability.

#### Strict domain modeling <a id="structure-domain-modeling-strict-domain"></a>

**MUST** — Use strict domain modeling.

#### Illegal states unrepresentable <a id="structure-domain-modeling-illegal-states-unrepresentable"></a>

**MUST** — Make illegal states unrepresentable in the domain layer. Domain objects should not have a public way to be created in an illegal state.

#### Domain-only interfaces <a id="structure-domain-modeling-domain-only-interfaces"></a>

**MUST** — Access domain objects only via public methods that only accept other domain objects as parameters and only return other domain objects.

#### Domain operations <a id="structure-domain-modeling-domain-operations"></a>

**MUST** — Perform Comparison/Addition/Subtraction or any other operation via domain methods.

#### Wrap primitives <a id="structure-domain-modeling-wrap-primitives"></a>

**PREFER** — Always add a well-named wrapper around a primitive over a comment describing it.

#### Implement Comparable <a id="structure-domain-modeling-implement-comparable"></a>

**PREFER** — Always implement Comparable or similar interfaces over using primitive directly.

### 2. Architecture & Layering

#### No collapsed layers <a id="structure-architecture-no-collapsed-layers"></a>

**MUST NOT** — Collapse layers for simplicity.

#### Respect layering <a id="structure-architecture-respect-layering"></a>

**MUST** — Respect architectural layering.

#### No primitive leakage <a id="structure-architecture-no-primitive-leakage"></a>

**MUST** — Prevent primitive leakage across layers.

#### Separation over brevity <a id="structure-architecture-separation-over-brevity"></a>

**PREFER** — Separate concerns over saving lines of code.

### 3. Dead Code & Deletion

#### Check for dead code first <a id="structure-dead-code-check-dead-code"></a>

**MUST NOT** — Initiate code changes before making certain code is not dead.

#### Delete unused <a id="structure-dead-code-delete-unused"></a>

**MUST** — Delete tests, code, and production code only used in tests that are no longer relevant or used.

#### No code over maybe-necessary <a id="structure-dead-code-none-over-maybe"></a>

**PREFER** — No code over maybe-necessary code.

---

## B. Behavior

### 4. Failure Handling

#### No silent catch <a id="behavior-failure-handling-no-silent-catch"></a>

**MUST NOT** — Use try/catch blocks that do not rethrow (silencing failures).

#### No default on failure <a id="behavior-failure-handling-no-default-on-failure"></a>

**MUST NOT** — Return or use a default value when failing.

#### No default to satisfy contract <a id="behavior-failure-handling-no-default-to-satisfy-contract"></a>

**MUST NOT** — Use a default value to satisfy a contract.

#### No strategy fallback <a id="behavior-failure-handling-no-strategy-fallback"></a>

**MUST NOT** — Make code 'hardened' by trying another strategy when the first one fails.

#### Fail fast <a id="behavior-failure-handling-fail-fast"></a>

**MUST** — Fail fast on unexpected state.

#### Fail fast over fallback <a id="behavior-failure-handling-fail-fast-over-fallback"></a>

**PREFER** — Fail fast over trying another strategy.

---

## C. Verification

### 5. Testing

#### No muted tests <a id="verification-testing-no-muted-tests"></a>

**MUST NOT** — Mute or skip tests.

#### No coverage-only tests <a id="verification-testing-no-coverage-only-tests"></a>

**MUST NOT** — Write tests that discard return values just to increase coverage.

#### Assert values <a id="verification-testing-assert-values"></a>

**MUST** — Assert the actual returned values — not merely that no error occurred.

#### Add tests for new code <a id="verification-testing-add-tests-for-new-code"></a>

**MUST** — Add tests for new code.

#### Troubleshooting unit test <a id="verification-testing-troubleshooting-unit-test"></a>

**MUST** — Add a unit test for any exploratory troubleshooting, even without a natural home.

#### Alert on broken tooling <a id="verification-testing-alert-on-broken-tooling"></a>

**MUST** — Stop and alert if quality-measuring tools are not functioning or covering all code.

#### Refactor over mocking <a id="verification-testing-refactor-over-mocking"></a>

**PREFER** — Refactor over mocking — if setup is painful, split into smaller domain models or focused interfaces.

#### Setup pain as feedback <a id="verification-testing-setup-pain-as-feedback"></a>

**PREFER** — Treat setup pain as architectural feedback over reaching for mocks.

### 6. Quality Tooling

#### No global lint changes <a id="verification-quality-tooling-no-global-lint-changes"></a>

**MUST NOT** — Change global or project-wide linting rules (e.g., `biome.json`, `stylecop.json`, `stylecop.ruleset`, `tsconfig.json`, `golangci.yaml`).

#### No global quality changes <a id="verification-quality-tooling-no-global-quality-changes"></a>

**MUST NOT** — Change global or project-wide quality standards (e.g., `knip.json`, test coverage thresholds in `package.json`).

#### No disabling via pragma <a id="verification-quality-tooling-no-disable-via-pragma"></a>

**MUST NOT** — Disable linting rules via comments or pragmas (e.g., `// eslint-disable-next-line`, `@ts-ignore`, `/* @ts-expect-error */`).

#### No committing generated code <a id="verification-quality-tooling-no-commit-generated"></a>

**MUST NOT** — Commit generated code.

#### Strict presets <a id="verification-quality-tooling-strict-presets"></a>

**MUST** — Use the strictest possible presets on linting and style.

#### Fix over mute <a id="verification-quality-tooling-fix-over-mute"></a>

**PREFER** — Correct a hundred linting problems instead of letting one bug slip through.

#### Ask over hack <a id="verification-quality-tooling-ask-over-hack"></a>

**PREFER** — Ask for guidance on how to solve tricky linting rules instead of 'hacking' it.

---

See [`PHILOSOPHY.md`](./PHILOSOPHY.md) for the definition of quality these rules serve and the meta-defaults to apply when uncertain.

See [`WORKFLOW.md`](./WORKFLOW.md) for git and process rules that are out of scope here.
