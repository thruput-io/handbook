# Thruput Backend AI Constitution

## 1. Normative Language

The key words MUST, MUST NOT, SHOULD, and MAY are interpreted as defined in RFC 2119.

## 2. Architecture

Every backend microservice MUST contain:

- Domain layer
- Application layer (Service layer)
- Infrastructure layer
- Contract project
- Host project (API / Worker)

Dependency direction MUST be:

- Host → Application → Domain
- Infrastructure → (Application + Domain via interfaces only)

The Domain layer MUST NOT depend on Infrastructure.
Controllers MUST NOT access repositories directly.

## 3. Domain Rules

The Domain layer:

- MUST be immutable.
- MUST enforce invariants in constructors or factories.
- MUST make invalid states unrepresentable.
- MUST NOT contain primitives.
- MUST wrap all primitives using `PrimitiveWrapper` subclasses.
- MUST NOT contain framework or I/O code.

### Primitive Wrapping

All primitives MUST be wrapped.

Subclasses of `PrimitiveWrapper` MUST have private constructors.

Each semantic concept MUST have its own type.

Types MUST NOT be reused across semantic meanings.

#### Example

`Lead.CreatedAt` MUST NOT be `Instant`.
It MUST be a dedicated type such as `LeadCreatedAt`.

## 4. Contract First

All REST APIs MUST be contract-first.

Contracts MUST reside in the `Contract` project.

Application code MUST depend on contracts, not the opposite.

## 5. Application Layer

The Application layer:

- MUST orchestrate use cases.
- MUST enforce transaction boundaries.
- MUST call repositories via interfaces.
- MUST NOT contain infrastructure implementation details.
- MUST NOT leak primitives.

## 6. Build Discipline

After each change:

- The solution MUST build.
- All warnings MUST be fixed.
- All tests MUST pass.

## 7. Testing

- Bugs MUST be reproduced with a failing test before fixing.
- Integration tests MUST use application entry points (API or streams).
- Integration tests SHOULD prefer raw JSON over domain models.
- Infrastructure shortcuts MUST NOT be used.

## 8. Temporary Files

- Temporary files MUST be created in `.tmp/`.
- Temporary files MUST NOT be created in the repository root.

## 9. AI Behavioral Constraint

The AI:

- MUST NOT collapse layers.
- MUST NOT bypass the Application layer.
- MUST NOT introduce primitive leakage.
- MUST default to strict domain modeling.
- MUST prioritize correctness over brevity.