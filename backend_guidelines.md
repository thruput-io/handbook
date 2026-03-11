# Thruput Backend AI Constitution

## 2. Architecture

Every backend microservice SHOULD contain:

- Domain layer
- Application layer
- Infrastructure layer
- Contract project
- Host project (API / Worker)

Dependency direction SHOULD be:

- Host → Application → Domain
- Infrastructure → (Application + Domain via interfaces only)

The Domain layer SHOULD NOT depend on Infrastructure.
Controllers SHOULD NOT access repositories directly.

## 3. Domain Rules

The Domain layer:

- SHOULD be immutable.
- SHOULD enforce invariants in constructors or factories.
- SHOULD make invalid states unrepresentable.
- SHOULD NOT contain primitives.
- SHOULD wrap all primitives using `PrimitiveWrapper` subclasses.
- SHOULD NOT contain framework or I/O code.

### Primitive Wrapping

All primitives SHOULD be wrapped.

Subclasses of `PrimitiveWrapper` SHOULD have private constructors.

Each semantic concept SHOULD have its own type.

Types SHOULD NOT be reused across semantic meanings.

#### Example

`Lead.CreatedAt` SHOULD NOT be `Instant`.
It SHOULD be a dedicated type such as `LeadCreatedAt`.

## 4. Contract First

All REST APIs SHOULD be contract-first.

Contracts SHOULD reside in the `Contract` project.

Application code SHOULD depend on contracts, not the opposite.

## 5. Application Layer

The Application layer:

- SHOULD orchestrate use cases.
- SHOULD enforce transaction boundaries.
- SHOULD call repositories via interfaces.
- SHOULD NOT contain infrastructure implementation details.
- SHOULD NOT leak primitives.

## 6. Build Discipline

After each change:

- The solution SHOULD build.
- All warnings SHOULD be fixed.
- All tests SHOULD pass.

## 7. Testing

- Bugs SHOULD be reproduced with a failing test before fixing.
- Integration tests SHOULD use application entry points (API or streams).
- Integration tests SHOULD prefer raw JSON over domain models.
- Infrastructure shortcuts SHOULD NOT be used.

## 8. Temporary Files

- Temporary files SHOULD be created in `.tmp/`.
- Temporary files SHOULD NOT be created in the repository root.

## 9. AI Behavioral Constraint

The AI:

- SHOULD NOT collapse layers.
- SHOULD NOT bypass the Application layer.
- SHOULD NOT introduce primitive leakage.
- SHOULD default to strict domain modeling.
- SHOULD prioritize correctness over brevity.