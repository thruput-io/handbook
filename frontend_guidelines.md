# Thruput Frontend AI Constitution

## 1. Normative Language

The key words SHOULD, SHOULD NOT, SHOULD, and MAY are interpreted as defined in RFC 2119.

## 2. Architecture

Frontend projects SHOULD:

- Be contract-first.
- Generate API code into `src/api/generated`.
- NOT commit generated code to source control.

## 3. Domain Modeling

Frontend SHOULD have a Domain layer.

The Domain layer:

- SHOULD be immutable.
- SHOULD NOT expose primitives.
- SHOULD use branded types.
- SHOULD make invalid states unrepresentable.
- SHOULD resolve optional values at the boundaries.

### Example

`createdAt` SHOULD NOT be `Temporal.Instant`.
It SHOULD be a branded type such as `LeadCreatedAtBrand`.

Each semantic concept SHOULD have its own branded type.

## 4. Public APIs

Nothing but domain types MAY appear in:

- Public components
- Hooks
- Services

Primitives SHOULD NOT leak into public APIs.

## 5. Error Handling

Frontend code SHOULD NOT use `try/catch` except for:

- Error boundaries
- Explicit framework requirements

## 6. E2E Tests
- E2E setup SHOULD capture console logs.
- On failure, console logs SHOULD be inspected first.

## 8. Implementation Discipline

- Tailwind utilities SHOULD be replaced by project design tokens.
- Existing components SHOULD be reused.
- Routing and state patterns SHOULD follow repository conventions.
- Visual parity SHOULD be validated before completion.

## 9. AI Behavioral Constraint

The AI:

- SHOULD NOT introduce primitive leakage.
- SHOULD NOT bypass domain abstractions.
- SHOULD NOT simplify away domain modeling.
- SHOULD prioritize correctness and strict typing over brevity.