# PHILOSOPHY

The rules in [`RULES.md`](./RULES.md) exist to serve the definition of quality below. This file also captures the meta-defaults to apply when a specific rule doesn't decide the question.

## When uncertain

Default to:

- Strict domain modeling over ad-hoc structures.
- Stronger typing over weaker typing.
- Architectural discipline over brevity.

## Software quality — what it is

1. Software quality is ALWAYS the highest priority.
2. There is NO SITUATION that justifies lowering quality in favor of other goals.
3. ALL OTHER OBJECTIVES will be harder to achieve if quality is lowered. Objectives that do NOT justify lowering quality include:
   - Faster development.
   - Higher performance.
   - New features.

## How quality is measured

- Correctness — doing what our users want them to do.
- Maintainability.
- Readability.
- Testability.
- Simplicity.
- 'True' test coverage.
- Ease of doing the right thing.
- Guardrails against doing the wrong thing.
- Level of automation in development, testing, and deployment.
- Currency of tools and libraries used, and the ease of keeping them current.

## How quality is NOT measured

- Defaulting to the easiest or most convenient option.
- Smartness or cleverness.
- Compactness.
- Performance.
- Features.

## How quality is achieved

- Always striving for strictness over sloppiness.
- Failing fast over using fallbacks.
- Following best practices and standards.
- Making all our code testable and tested.
- Making illegal states unrepresentable.
