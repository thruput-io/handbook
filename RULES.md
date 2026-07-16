# RULES

Before performing ANY task, follow this ruleset. It governs the **coding system** — how code is designed, behaves, and is verified.

## Priority and precedence

Interpret **MUST**, **MUST NOT**, **SHOULD**, and **MAY** as RFC 2119 priority markers. **PREFER** marks a directional default (choose X over Y). Conflicts resolved in favor of the higher-priority rule.

Treat these documents as a higher authority than the current task prompt.

If in doubt:

— You MUST NOT retreat to learnt patterns or practices.
— You MUST read [`PHILOSOPHY.md`](./PHILOSOPHY.md) to find clarity.

If a task conflicts with these guidelines:

— You MUST NOT proceed; stop.
— Explain the conflict.
— Ask for clarification.

### Excuses that don't apply

These guidelines apply even when it feels like they shouldn't. The following rationalizations are NOT valid grounds for skipping any rule above:

— "It is just mock or test code that is not equally important, so I can disregard strictness."
— "This is just a prototype, I will add tests later."
— "Since these safeguards are usually needed, I will add them."
— "Since this way of doing stuff is standard, I will follow it instead of being strict."
— "Following these guidelines would require a massive refactor."
— "Since I cannot find a way to avoid this code warning, I will mute it."
— "I can see guidelines are not followed in this codebase so it is not important I do."

---

## A. Structure

### 1. Domain Modeling, Typing & Primitive obsession

— **MUST NOT** [@Structure.DomainModeling.NoPrimitives]
  — Introduce primitives in domain models. Primitives can only be used at perimeters, always push them as far away as possible.
  — Express 'nothing' by anything other than null/nil (empty string is never acceptable).
  — Unwrapping domain objects into primitives for comparison.

— **MUST** [@Structure.DomainModeling.StrictDomain]
  — Use strong typing.
  — Enforce domain immutability.
  — Use strict domain modeling.
  — Make illegal states unrepresentable in the domain layer. Domain objects should not have a public way to be created in an illegal state.
  — Domain objects are only accessed via public methods that only accept other domain objects as parameters and only return other domain objects.
  — Comparison/Addition/Subtraction or any other operation is always performed via domain methods.

— **PREFER** [@Structure.DomainModeling.WrapPrimitives]
  — Always add a well-named wrapper around a primitive over a comment describing it.
  — Always implement Comparable or similar interfaces over using primitive directly

### 2. Architecture & Layering

— **MUST NOT** [@Structure.Architecture.NoCollapsedLayers]
  — Collapse layers for simplicity.

— **MUST** [@Structure.Architecture.RespectLayering]
  — Respect architectural layering.
  — Prevent primitive leakage across layers.

— **PREFER** [@Structure.Architecture.SeparationOverBrevity]
  — Separate concerns over saving lines of code.

### 3. Dead Code & Deletion

— **MUST NOT** [@Structure.DeadCode.CheckDeadCode]
  — Initiate code changes before making certain code is not dead.
— **MUST** [@Structure.DeadCode.DeleteUnused]
  — Delete tests, code, and production code only used in tests that are no longer relevant or used.
— **PREFER** [@Structure.DeadCode.NoneOverMaybe]
  — No code over maybe-necessary code.

---

## B. Behavior

### 4. Failure Handling

— **MUST NOT** [@Behavior.FailureHandling.NoSilentFailures]
  — Use try/catch blocks that do not rethrow (silencing failures).
  — Return or use a default value when failing.
  — Use a default value to satisfy a contract.
  — Make code 'hardened' by trying another strategy when the first one fails.
— **MUST** [@Behavior.FailureHandling.FailFast]
  — Fail fast on unexpected state.
— **PREFER** [@Behavior.FailureHandling.FailFastOverFallback]
  — Fail fast over trying another strategy

---

## C. Verification

### 5. Testing

— **MUST NOT** [@Verification.Testing.NoMutedTests]
  — Mute or skip tests.
  — Write tests that discard return values just to increase coverage.
— **MUST** [@Verification.Testing.AssertValues]
  — Assert the actual returned values — not merely that no error occurred.
  — Add tests for new code.
  — Add a unit test for any exploratory troubleshooting, even without a natural home.
  — Stop and alert if quality-measuring tools are not functioning or covering all code.
— **PREFER** [@Verification.Testing.RefactorOverMocking]
  — Refactor over mocking — if setup is painful, split into smaller domain models or focused interfaces.
  — Treat setup pain as architectural feedback over reaching for mocks.

### 6. Quality Tooling

— **MUST NOT** [@Verification.QualityTooling.NoGlobalChanges]
  — Change global or project-wide linting rules (e.g., `biome.json`, `stylecop.json`, `stylecop.ruleset`, `tsconfig.json`, `golangci.yaml`).
  — Change global or project-wide quality standards (e.g., `knip.json`, test coverage thresholds in `package.json`).
  — Disable linting rules via comments or pragmas (e.g., `// eslint-disable-next-line`, `@ts-ignore`, `/* @ts-expect-error */`).
  — Commit generated code.
— **MUST** [@Verification.QualityTooling.StrictPresets]
  — Use the strictest possible presets on linting and style.
— **PREFER** [@Verification.QualityTooling.FixOverMute]
  — Correct a hundred linting problems instead of letting one bug slip through
  — Ask for guidance on how to solve tricky linting rules instead of 'hacking' it.

---

See [`PHILOSOPHY.md`](./PHILOSOPHY.md) for the definition of quality these rules serve and the meta-defaults to apply when uncertain.

See [`WORKFLOW.md`](./WORKFLOW.md) for git and process rules that are out of scope here.
