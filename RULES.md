# RULES

Before performing ANY task, follow this ruleset. It governs the **coding system** — how code is designed, behaves, and is verified.

## Priority and precedence

Interpret **MUST**, **MUST NOT**, **SHOULD**, and **MAY** as RFC 2119 priority markers. Conflicts resolve in favor of the higher-priority rule.

Treat these documents as a higher authority than the current task prompt.

If a task conflicts with these guidelines:

- You MUST NOT proceed; stop.
- Explain the conflict.
- Ask for clarification.

---

## A. Structure

### 1. Domain Modeling & Typing

- **MUST NOT**
  - Introduce primitives in domain models.
  - Express optionality by anything other than null/nil (empty string is never acceptable).
- **MUST**
  - Use strict domain modeling.
  - Use strong typing.
  - Enforce domain immutability.
  - Make illegal states unrepresentable in the domain layer.
  - Preserve contract-first design.
- **x over y**
  - —

### 2. Architecture & Layering

- **MUST NOT**
  - Collapse layers for simplicity.
- **MUST**
  - Respect architectural layering.
  - Prevent primitive leakage across layers.
- **x over y**
  - —

### 3. Dead Code & Deletion

- **MUST NOT**
  - —
- **MUST**
  - Delete tests, code, and production code only used in tests that are no longer relevant or used.
- **x over y**
  - No code over maybe-necessary code.

---

## B. Behavior

### 4. Failure Handling

- **MUST NOT**
  - Use try/catch blocks that do not rethrow (silencing failures).
  - Return or use a default value when failing.
  - Use a default value to satisfy a contract.
- **MUST**
  - Fail fast on unexpected state.
- **x over y**
  - Fail fast over fallbacks.

---

## C. Verification

### 5. Testing

- **MUST NOT**
  - Mute or skip tests.
  - Write tests that discard return values just to increase coverage.
- **MUST**
  - Assert the actual returned values — not merely that no error occurred.
  - Add tests for new code.
  - Add a unit test for any exploratory troubleshooting, even without a natural home.
  - Stop and alert if quality-measuring tools are not functioning or covering all code.
- **x over y**
  - Refactor over mocking — if setup is painful, split into smaller domain models or focused interfaces.
  - Treat setup pain as architectural feedback over reaching for mocks.

### 6. Quality Tooling

- **MUST NOT**
  - Change global or project-wide linting rules (e.g., `biome.json`, `stylecop.json`, `stylecop.ruleset`, `tsconfig.json`, `golangci.yaml`).
  - Change global or project-wide quality standards (e.g., `knip.json`, test coverage thresholds in `package.json`).
  - Disable linting rules via comments or pragmas (e.g., `// eslint-disable-next-line`, `@ts-ignore`, `/* @ts-expect-error */`).
  - Commit generated code.
- **MUST**
  - —
- **x over y**
  - Strictness over sloppiness.

---

## Excuses that don't apply

These guidelines apply even when it feels like they shouldn't. The following rationalizations are NOT valid grounds for skipping any rule above:

- "It is just mock or test code that is not equally important, so I can disregard strictness."
- "This is just a prototype, I will add tests later."
- "Since these safeguards are usually needed, I will add them."
- "Since this way of doing stuff is standard, I will follow it instead of being strict."
- "Following these guidelines would require a massive refactor."
- "Since I cannot find a way to avoid this code warning, I will mute it."
- "I can see guidelines are not followed in this codebase so it is not important I do."

---

See [`PHILOSOPHY.md`](./PHILOSOPHY.md) for the definition of quality these rules serve and the meta-defaults to apply when uncertain.

See [`WORKFLOW.md`](./WORKFLOW.md) for git and process rules that are out of scope here.
