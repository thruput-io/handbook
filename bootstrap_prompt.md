Before performing ANY task:

1. Load and read the following files in this order:
    1. .junie/project_guidelines.md
    2. .junie/backend_guidelines.md (if project is Backend)
    3. .junie/frontend_guidelines.md (if project is Frontend)

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
    - Fail fast over using fallbacks.
    - Add a unit test for any exploratory troubleshooting even if there is no natural home for it.
    - Always strive for strictness, never allow sloppy code.
    - Every test should assert the actual returned values, not just that no error occurred.

7. You SHOULD NOT:
     - Express optionality in any other way than by null, empty string is never okay.
     - Return or use a default value when failing.
     - Use a default value for satisfying a contract.
     - Disable linting rules via comment, pragma or similar.
     - Collapse layers for simplicity.
     - Bypass the Application layer.
     - Introduce primitives in domain models.
     - Commit generated code.
     - Make assumptions without evidence. 
     - Write tests that discard return values without asserting them just to increase coverage.

8. When uncertain you SHOULD:
    - Default to strict domain modeling.
    - Default to stronger typing.
    - Default to architectural discipline over brevity.

9. PHILOSOPHY AND PRINCIPLES YOU SHOULD HONOR:
   1. THE QUALITY of our software is ALWAYS the highest priority
   2. There is NO SITUATION that rectifies lowering of the quality in favor of other objectives
   3. ALL OTHER OBJECTIVES will be harder to achieve if the quality is lowered, such as:
      - Faster development
      - Higher performance
         - Cool features
   4. QUALITY of software is measured by:
      - Correctness, doing what our users want it to do
      - Maintainability
      - Readability
      - Testability
      - Simplicity
      - 'True' test coverage
      - Easiness of doing right
      - Guardrails for doing wrong
      - Level of automation in development, testing, and deployment
      - Actuality of tools and libraries used and at what ease staying so is
   5. QUALITY of software is NOT measured by:
      - Smartness or cleverness
      - Compactness
      - Performance
      - Features
   6. We achieve QUALITY by:
      - By always striving for strictness over sloppiness
      - Failing fast over using fallbacks
      - Following best practices and standards
      - Making all our code testable and tested
      - By making illegal states unrepresentable
