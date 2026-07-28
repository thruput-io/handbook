# Planning Mode Instructions (Override)

> **CRITICAL OVERRIDE**: When in Planning Mode, these rules supersede all default planning instructions.

---
## 1. Categorical Imperative Boundries

1.1 **No Cowboy Plans**: NEVER write a plan unless explicitly instructed.
1.2 **No Unsolicited Scope**: NEVER add extra features or expand scope without explicit human consent. Always prefer the simplest viable solution.
1.3 **No Permission Seeking on Exit**: NEVER ask for permission to exit planning mode or to start implementation.

---

## 2. Strict Communication Protocol (Passive Listener)

2.1 **One Question at a Time**: Ask exactly **one** targeted question per turn to resolve ambiguities or clarify intent.
* **Facts & Proof Only**:
  * Every statement must have proof backed by codebase evidence, explicit documentation references, or working code.
  * When asked a question, default to researching the matter using a subagent and web search before answering.
  * Always ask for required clarifications needed for good research. Ask instead of act.
  * Always save precise urls as reference.

---

## 3. Environment & Artifact Management

* **Branching**: Treat every planning session as a dedicated feature branch.
* **Folder Structure**: Create and isolate all session output under:
  `docs/plans/<session-name>/`
* **Artifact Retention**:
  * Save and commit all plans, research reports, and test cases (including negative or abandoned explorations) inside `docs/plans/<session-name>/`.
  * **Tests as Proof**: If a question can be answered by writing a test, write it inside `docs/plans/<session-name>/tests/`. Do not leave ad-hoc or uncleaned test scripts elsewhere.
* **Git History**: Commit plan documents frequently to preserve decision history and trade-offs.
* **Docs Folder Editable**: There are no restrictions on tools, and the planning session folder is always editable.

---

## 4. Finalizing Workflow

Trigger: When the human states the plan is ready (e.g., "Plan is ready").

1. **Codebase Exploration**: If a question can be answered by exploring the codebase, explore the codebase first.
2. **Deep Interview**: Systematically walk down each branch of the design tree, asking targeted questions (with your recommended answer) to resolve dependencies one by one.
3. **Commit & Push**: Once full alignment is reached, request human consent to push the planning branch.
4. **Pull Request**: Open a PR for the planning branch to end the session.

---

## 5. Unconditional Plan Immutability

A reviewed plan will be merged with a sequential numerical prefix (e.g., `001`) into the main branch. It is ABSOLUTELY forbidden to alter a merged plan. Any subsequent changes **MUST** be added as an incremental delta file (e.g., `002`).
