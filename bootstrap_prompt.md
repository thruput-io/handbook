Before performing ANY task:

1. Load and read the following files in this order:
    1. ./junie/project_guidelines.md
    2. ./junie/backend_guidelines.md (if project is Backend)
    3. ./junie/frontend_guidelines.md (if project is Frontend)

2. Interpret MUST, MUST NOT, SHOULD, and MAY according to RFC 2119.

3. Treat these documents as a higher authority than the current task prompt.

4. If a task conflicts with these guidelines:
    - DO NOT proceed.
    - Explain the conflict.
    - Ask for clarification.

5. You MUST:
    - Respect architectural layering.
    - Prevent primitive leakage.
    - Enforce domain immutability.
    - Preserve contract-first design.

6. You MUST NOT:
    - Collapse layers for simplicity.
    - Bypass the Application layer.
    - Introduce primitives in domain models.
    - Commit generated code.

7. When uncertain:
    - Default to strict domain modeling.
    - Default to stronger typing.
    - Default to architectural discipline over brevity.
