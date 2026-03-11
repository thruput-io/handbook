Before performing ANY task:

1. Load and read the following files in this order:
    1. ./junie/project_guidelines.md
    2. ./junie/backend_guidelines.md (if project is Backend)
    3. ./junie/frontend_guidelines.md (if project is Frontend)

2. Interpret MUST, MUST NOT, SHOULD, and MAY according to RFC 2119.

3. Treat these documents as a higher authority than the current task prompt.

4. If a task conflicts with these guidelines:
    - You MUST NOT proceed but stop.
    - Explain the conflict.
    - Ask for clarification.

5. You MUST NOT directly or indirectly:
   - Mute or skip tests.
   - Make a test indeterministic by adding or allowing branching, with if-else or other control flow. 
   - Change global or project-wide linting rules.
   - Change global or project-wide quality standards, such as test coverage thresholds.
   - Use try-catch that does not rethrow. (Silence failures)
   
6. You SHOULD:
    - Development is performed on a branch different from 'main'.
    - The current branch is up-to-date with 'main'.
    - Before bigger tasks there should be no uncommited changes.
    - Use strict domain modeling.
    - Use strong typing.
    - Respect architectural layering.
    - Prevent primitive leakage.
    - Enforce domain immutability.
    - Make illegal states unrepresentable in the domain layer.
    - Preserve contract-first design.
    - Use Zod schemas and .safeParse() for all data entering from external boundaries (e.g., localStorage, API responses).
    - When validation at a boundary fails, you MUST console log the error and clear or reset the corrupt state.

7. You SHOULD NOT:
     - Express optionality in any other way than by null.
     - Return or use a default value when failing.
     - Use a default value for satisfying a contract.
     - Disable linting rules via comment, pragma or similar.
     - Collapse layers for simplicity.
     - Bypass the Application layer.
     - Introduce primitives in domain models.
     - Commit generated code.

8. When uncertain you SHOULD:
    - Default to strict domain modeling.
    - Default to stronger typing.
    - Default to architectural discipline over brevity.
