# PHILOSOPHY

The rules in [`RULES.md`](./RULES.md) exist to serve the definition of quality below. This file also captures the meta-defaults to apply when a specific rule doesn't decide the question.

## When uncertain

Default to:

— **PREFER** [@Philosophy.Uncertainty.StrictDomainModelingOverAdHoc]
— Strict domain modeling over ad-hoc structures. See [@Structure.DomainModeling.StrictDomain].

— **PREFER** [@Philosophy.Uncertainty.StrongerTypingOverWeakerTyping]
— Stronger typing over weaker typing. See [@Structure.DomainModeling.StrictDomain].

— **PREFER** [@Philosophy.Uncertainty.ArchitectureOverBrevity]
— Architectural discipline over brevity. See [@Structure.Architecture.SeparationOverBrevity].

## Software quality — what it is

— **MUST** [@Philosophy.Quality.HighestPriority]
— Software quality is ALWAYS the highest priority.

— **MUST NOT** [@Philosophy.Quality.NoQualityTradeoff]
— There is NO SITUATION that justifies lowering quality in favor of other goals.

— **MUST** [@Philosophy.Quality.QualityEnablesGoals]
— ALL OTHER OBJECTIVES will be harder to achieve if quality is lowered. Objectives that do NOT justify lowering quality include:
  - Faster development.
  - Higher performance.
  - New features.

## How quality is measured

— **MUST** [@Philosophy.Measurement.Attributes]
— Quality is measured by the following attributes:
  - Correctness — the software does what our users want it to do.
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

— **MUST NOT** [@Philosophy.NonMeasurement.Attributes]
— Quality is NOT measured by any of the following:
  - Defaulting to the easiest or most convenient option.
  - Smartness or cleverness.
  - Compactness.
  - Performance.
  - Features.

## How quality is achieved

— **PREFER** [@Philosophy.Achievement.StrictnessOverSloppiness]
— Always striving for strictness over sloppiness.

— **PREFER** [@Philosophy.Achievement.FailFastOverFallbacks]
— Failing fast over using fallbacks. See [@Behavior.FailureHandling.FailFastOverFallback].

— **MUST** [@Philosophy.Achievement.BestPracticesAndStandards]
— Following best practices and standards.

— **MUST** [@Philosophy.Achievement.TestableAndTested]
— Making all our code testable and tested.

— **MUST** [@Philosophy.Achievement.IllegalStatesUnrepresentable]
— Making illegal states unrepresentable. See [@Structure.DomainModeling.StrictDomain].

---

See [`RULES.md`](./RULES.md) for the enforceable rules that operationalize this philosophy.

See [`WORKFLOW.md`](./WORKFLOW.md) for git and process rules.
