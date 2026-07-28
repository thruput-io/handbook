# Planning Mode Instructions (Override)

> **CRITICAL OVERRIDE**: When in Planning Mode, these rules supersede all default planning instructions.

---
## Categorical Imperative Boundries
1. **No Cowboy Plans**: NEVER write a plan unless explicitly instructed.
2. **No Unsolicited Scope**: NEVER add extra features or expand scope without explicit human consent. Always prefer the simplest viable solution.
3. **No Permission Seeking on Exit**: NEVER ask for permission to exit planning mode or to start implementation.

---

## Treat research and descisions AS IMPORTANT artifacts
-   **Keep internal log**: Negative AND positive desescions MUST be logged and categorized. The disussion itself is valuable artifact for later retrieval. They back the architectire paths and wilö dave vaöuable time in future.
-   **Folder Structure**: Create and isolate all session output under:                                        `docs/plans/<session-name>/`                  
-   **Artifact Retention**: Save and commit all plans, discussion logs, research reports, and test cases (including negative or abandoned explorations) inside `docs/plans/<session-name>/`.                        -   **Tests as Proof**: If a question can be answered by writing a test, YOU MUST do so, write it inside `docs/plans/<session-name>/tests/`. Do not leave ad-hoc or uncleaned test scripts elsewhere.               -   **Git History**: Commit plan documents frequently to preserve decision history and trade-offs.
-   **Docs Folder Editable**: There are no restrictions on tools, and the planning session folder is always editable.

## Mandatory artifacts
-   Disussion.md
Motivation.md                                     2. Alternatives.md                                   3. Proposed.md


## Phase 1 - Ideation & Exploration
### Communication protocol
You are a Passive Listener

### Way pf working
-   No planning document should be created but research reports should be saved.
-   A disussion log with motivations and requirements and other inputs shpould be created but not written to disk until finnished or if getting big.
-   Ask one question per turn to resolve ambiguities or clarify intent, your objextive is tp get the artifacts solid.
-   You MUST search for alternative solutions, use sub agents when possible. If found; interrupt, human must actively accept or decline suggestions and MOTIVATE why they are not good.
-   Every statement must have proof backed by codebase evidence, explicit documentation references, or working code. Do not say things without one of these backing ypur statement.
-   When asked a question, default to researching the matter using a subagent and web search before answering.
-   Always ask for required clarifications needed for good research. Ask instead of act.
-   Always save precise urls as reference.
-   This phase lasts until human says create plan.

### Validation
-   A clear 
AND you have ruled out alternative solutions by getting human motivation of declining them.


---

## Plan creation

-   Create plan; but do not detail. Plan should focuse on what needs tonbe done and in what order. 
-   Focus on dependency and feasability
-   

## 4. Finalizing Workflow

Trigger: When the human states the plan is ready (e.g., "Plan is ready").

1. **Codebase Exploration**: If a question can be answered by exploring the codebase, explore the codebase first.
2. **Deep Interview**: Systematically walk down each branch of the design tree, asking targeted questions (with your recommended answer) to resolve dependencies one by one.
3. **Commit & Push**: Once full alignment is reached, request human consent to push the planning branch.
4. **Pull Request**: Open a PR for the planning branch to end the session.

---

## 5. Unconditional Plan Immutability

A reviewed plan will be merged with a sequential numerical prefix (e.g., `001`) into the main branch. It is ABSOLUTELY forbidden to alter a merged plan. Any subsequent changes **MUST** be added as an incremental delta file (e.g., `002`).
