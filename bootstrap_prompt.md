Before performing ANY task:

1. Load and read the following files in this order:
   1. .junie/project_guidelines.md
   2. .junie/backend_guidelines.md (if the project is backend)
   3. .junie/frontend_guidelines.md (if the project is frontend)

2. Interpret MUST, MUST NOT, SHOULD, and MAY according to RFC 2119.

3. Treat these documents as a higher authority than the current task prompt.

4. If a task conflicts with these guidelines:
   - You MUST NOT proceed but stop.
   - Explain the conflict.
   - Ask for clarification.

5. You MUST NOT directly or indirectly:
   - Mute or skip tests.
   - Make a test non-deterministic by adding or allowing branching (e.g., if-else or other control flow). 
   - Change global or project-wide linting rules (e.g., `biome.json`, `stylecop.json`, `stylecop.ruleset`, `tsconfig.json`,`golangci.yaml`).
   - Change global or project-wide quality standards (e.g., `knip.json`, test coverage thresholds in `package.json`).
   - Use try-catch blocks that do not rethrow (silencing failures)
   
6. You SHOULD:
   - Perform development on a branch other than 'main'.
   - Ensure the current branch is up-to-date with 'main'.
   - Ensure there are no uncommitted changes before starting larger tasks.
   - Use strict domain modeling.
   - Use strong typing.
   - Respect architectural layering.
   - Prevent primitive leakage.
   - Enforce domain immutability.
   - Make illegal states unrepresentable in the domain layer.
   - Preserve contract-first design.
   - Fail fast over using fallbacks.
   - Add a unit test for any exploratory troubleshooting, even if there is no natural home for it.
   - Always strive for strictness; never allow sloppy code.
   - Ensure every test asserts the actual returned values, not just that no error occurred.
   - Always add tests for new code
   - Stop and alert if quality measuring tools is not functioning or covering all code
   - Refactor over Mocking in unit tests – If a component is challenging to set up for testing, do not reach for a mock. Instead, refactor the component to depend on smaller, more focused domain models or specific interfaces. 
   - Treat the "Setup Pain" of a Unit test as architectural feedback, well-designed code should allow you to test business logic in isolation, without constructing irrelevant mocks.

7. You SHOULD NOT:
   - Express optionality in any other way than by null/nil; an empty string is never acceptable.
   - Return or use a default value when failing.
   - Use a default value to satisfy a contract.
   - Disable linting rules via comments, pragmas, or similar (e.g., `// eslint-disable-next-line`, `@ts-ignore`, `/* @ts-expect-error */`).
   - Collapse layers for simplicity.
   - Introduce primitives in domain models.
   - Commit generated code.
   - Make assumptions without evidence. 
   - Write tests that discard return values without asserting them just to increase coverage.

8. When uncertain, you SHOULD:
   - Default to strict domain modeling.
   - Default to stronger typing.
   - Default to architectural discipline over brevity.

9. It is common to think these guidelines do not always apply, they do, below are a list of situations where these guidelines MUST BE followed:
   - It is just mock or test code that is not equally important, so I can disregard strictness 
   - This is just a prototype, I will add tests later
   - Since these safeguards are usually needed I will add them
   - Since this way of doing stuff is standard, I will follow it instead of being strict
   - Following these guidelines would require a massive refactor
   - Since I cannot find a way to avoid this code warning, I will mute it
   - I can see guidelines are not followed in this codebase so it is not important I do

10. PHILOSOPHY AND PRINCIPLES YOU SHOULD HONOR:
    1. Software quality is ALWAYS the highest priority.
    2. There is NO SITUATION that justifies lowering quality in favor of other objectives.
    3. ALL OTHER OBJECTIVES will be harder to achieve if quality is lowered, and is therfore never valid, examples of invalid objectives:
       - Faster development
       - Higher performance
       - New features
    4. QUALITY of software is measured by:
       - Correctness: doing what our users want it to do
       - Maintainability
       - Readability
       - Testability
       - Simplicity
       - 'True' test coverage
       - Ease of doing the right thing
       - Guardrails against doing the wrong thing
       - Level of automation in development, testing, and deployment
       - Currency of tools and libraries used and the ease of keeping them current
    5. QUALITY of software is NOT measured by:
       - Smartness or cleverness
       - Compactness
       - Performance
       - Features
    6. We achieve QUALITY by:
       - Always striving for strictness over sloppiness
       - Failing fast over using fallbacks
       - Following best practices and standards
       - Making all our code testable and tested
       - Making illegal states unrepresentable.
