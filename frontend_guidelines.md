# Thruput Frontend AI Constitution

## 1. Normative Language

The key words MUST, MUST NOT, SHOULD, and MAY are interpreted as defined in RFC 2119.

## 2. Architecture

Frontend projects MUST:

- Be contract-first.
- Generate API code into `src/api/generated`.
- NOT commit generated code to source control.
- Use Zod for contract-based validation.

## 3. Domain Modeling

Frontend MUST have a Domain layer.

The Domain layer:

- MUST be immutable.
- MUST NOT expose primitives.
- MUST use branded types.
- MUST make invalid states unrepresentable.
- MUST resolve optional values at the boundaries.

### Example

`createdAt` MUST NOT be `Temporal.Instant`.
It MUST be a branded type such as `LeadCreatedAtBrand`.

Each semantic concept MUST have its own branded type.

## 4. Public APIs

Nothing but domain types MAY appear in:

- Public components
- Hooks
- Services

Primitives MUST NOT leak into public APIs.

## 5. Error Handling

Frontend code MUST NOT use `try/catch` except for:

- Error boundaries
- Explicit framework requirements

## 6. E2E Tests
- E2E setup MUST capture console logs.
- On failure, console logs MUST be inspected first.

## 7. Figma MCP Flow (Mandatory)
For Figma-driven changes:

1. `get_design_context` MUST be called first.
1. If truncated, `get_metadata` MUST be used.
1. `get_screenshot` MUST be retrieved.
1. Only then MAY implementation begin.
1. Output MUST be translated to project conventions.
1. Final UI MUST match Figma visually (1:1).

## 8. Implementation Discipline

- Tailwind utilities SHOULD be replaced by project design tokens.
- Existing components MUST be reused.
- Routing and state patterns MUST follow repository conventions.
- Visual parity MUST be validated before completion.

## 9. AI Behavioral Constraint

The AI:

- MUST NOT introduce primitive leakage.
- MUST NOT bypass domain abstractions.
- MUST NOT simplify away domain modeling.
- MUST prioritize correctness and strict typing over brevity.