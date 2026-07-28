# Planning Mode Instructions (Override)

> **CRITICAL OVERRIDE**: When in Planning Mode, these rules supersede all other planning instructions.

## Plan Disposition - Numbered Sections
1.  Background
2.  Objectives
Numbered list of goals
3.  Summary
Execution plan
4.  Detailed execution plan
Step-by-step plan divided in milestones
5.  Testing
Name of each test
6.  References
6.1 Tracer bullets
Test names and links to test files
6.2 Research
Summary from each piece of research and links to full reports
6.3 Alternatives
Rejected decisions
7.  Discussion
Compacted log of discussion with human

## Imperative Boundaries
1. **No Cowboy Plans**: DO NOT write anything in a plan without prior clarifying discussion with human. Only section 7 should be written without discussion.
2. **No Unsolicited Scope**: DO NOT add extra features or expand scope without explicit human consent. Always prefer the simplest solution.
3. **No Permission Seeking on Exit**: NEVER ask for permission to exit planning mode or to start implementation.

## Imperative Rules
1. **Complete Transparency**: Explain INTENT with every ACTION before EXECUTING
2. **Keep log**: Negative AND positive descriptions MUST be logged and categorized. The discussion itself is a valuable artifact for later retrieval. They back the architecture paths and will save valuable time in the future.
3. **Folder Structure**: Create and isolate all session output under: `docs/plans/{session-name}/` or subfolders to it
4. **Artifact Retention**: Save and commit plan, research reports, and test cases (including negative or abandoned explorations) inside `docs/plans/{session-name}/`. 
5. **Tests as Proof**: If a question can be answered by writing a test, YOU MUST do so, write it inside `docs/plans/{session-name}/tests/`. Do not make ad-hoc or uncleaned test scripts
6. **Git History**: Commit the plan document frequently to preserve checkpoints that human can revert to
7. **Docs Folder Editable**: There are no restrictions on tools, and the planning session folder is always editable.

## Planning Phase 1 - Permissions and Session Name
### Communication Protocol
Collaborative

### Way of Working
1.  With one question ask for human for permission to:
  - Read all (ls, cat, tail, head, grep, etc.)) files in repo and in sibling handbook repo
  - Create a session-folder (ASK human for name)
  - Any git command
  - Create update, delete anything within the session-folder
  - Use subagents for web research and permission needed to do so
2. Make sure git is up to date and clean
3. Read guidelines and ADRs
4. Create a planning branch named the same as the session
5. Create a session-folder

### Criteria for Starting the next Phase 
All steps in "Way of Working" completed successfully

## Planning Phase 2 – Ideation & Exploration
### Communication Protocol
- In the beginning you are a passive listener but eager to find the best solution via subagents, not interrupting human if not necessary.
- When plan is getting close to completion, you gradually change to interviewing the human relentlessly about the plan until reaching shared understanding, resolving each branch of the decision tree.

### Way of Working
- Section 4 and 5 MUST NOT be created or drafted
- For each question, provide your recommended answer
- You MUST make sure all sections except four and five are complete
- By asking one question per turn you will resolve ambiguities and clarify intent
- You MUST search for alternative solutions, use subagents when possible. If found to interrupt human, human must actively accept or decline suggestions and MOTIVATE why they are not good. If not found, document research done.
- Every statement from you must have proof backed by codebase evidence, explicit documentation references, or working test cases.
- When asked a question, default to researching the matter using a subagent and web search before answering.
- Always ask for required clarifications needed for good research. Ask instead of act.
- Always save precise url:s as a reference for findings.
- This phase lasts until a human explicitly asks for continuation and "Criteria for Starting the next Phase" is fulfilled

### Criteria for Starting the next Phase
- All Sections except 4 and 5 contain a logical coherent document
- You have presented all viable alternative solutions to human and received and documented motivation of human declining them
- You have made a through web search for third party libs fulfilling one or more goals of the plan and had human explicitly rejected them or incorporated them in the plan
---

## Plan creation
Write section 4 and 5


### Criteria for Ending Planning Session


3. **Commit & Push**: Once full alignment is reached, request human consent to push the planning branch.
4. **Pull Request**: Open a PR for the planning branch to end the session.

---

## 5. Unconditional Plan Immutability
A Reviewed Plan Will Be Merged with a Sequential Numerical Prefix (E.g., `001`) into the Main Branch. It Is ABSOLUTELY Forbidden to Alter a Merged Plan. Any Subsequent Changes **MUST** Be Added as an Incremental Delta File (E.g., `002`).
---
