# PHILOSOPHY

This is the foundation the rest of the handbook draws from: what we mean by quality, and why we work the
way we do. [`RULES.md`](./RULES.md) turns it into the enforceable requirements a review can cite.

Nothing here is a rule. There are no RFC 2119 markers in this file on purpose — a requirement that can be
violated belongs in [`RULES.md`](./RULES.md). What is here is the reasoning those rules serve, and the
default to fall back on when no rule decides the question.

## When uncertain

Default to strict domain modeling over ad-hoc structures, to stronger typing over weaker, and to
architectural discipline over brevity. Each of these is already required —
[Strict domain modeling](./RULES.md#strict-domain-modeling),
[Strong typing](./RULES.md#strong-typing),
[Separation over brevity](./RULES.md#separation-over-brevity) — so the point of naming them here is the
direction to lean when a case is not covered: the stricter reading of an unclear situation is the right
one.

## Software quality — what it is

Software quality is ALWAYS the highest priority. There is NO SITUATION that justifies lowering quality in
favor of other goals, because ALL OTHER OBJECTIVES become harder to reach once it drops. The three
objectives most often offered as justification are faster development, higher performance, and new
features. None of them qualify.

## How quality is measured

These are the terms to use when arguing about quality. They name the axes a change can be good or bad
along, so a review can say *which* kind of worse something is. They characterize a problem; they do not
settle it — the requirement being violated comes from [`RULES.md`](./RULES.md).

- **Correctness** — the software does what our users want it to do.
- **Maintainability** — changing one behaviour requires understanding and touching only the code that owns it.
- **Readability** — a reader unfamiliar with the code can say what it does, and why, without asking its author.
- **Testability** — behaviour can be exercised in isolation, without standing up the network, the clock, or global state.
- **Simplicity** — the design carries no structure that a present requirement does not demand.
- **True test coverage** — tests that fail when the behaviour breaks, as opposed to tests that merely execute the lines.
- **Ease of doing the right thing** — the correct approach is also the path of least resistance for the next contributor.
- **Guardrails against doing the wrong thing** — types, tests, and tooling make the wrong approach fail early, rather than merely discouraging it.
- **Automation** — how much of the distance between a change and its verified deployment runs without a human.
- **Currency of tools and libraries** — how current they are, and how easily they can be kept that way.

Simplicity and guardrails will sometimes point opposite ways, because a guardrail is structure that no
*functional* requirement demands. Resolve it in favor of the guardrail: the wrong approach failing early
is itself something we require, and so it counts as a present requirement.

## How quality is NOT measured

Quality is NOT measured by defaulting to the easiest or most convenient option, by smartness or
cleverness, by compactness, by performance, or by features.

Performance and features are requirements like any other — where one is specified, meeting it is part of
Correctness. What they are not is credit against the axes above. Code does not become good by being fast,
and a release does not become good by containing more.

## How quality is achieved

By always striving for strictness over sloppiness. By failing fast over using fallbacks. By following
best practices and standards. By making all our code testable and tested. By making illegal states
unrepresentable.

Strictness is the thread through all of them. It is also the one that cannot be checked mechanically,
which is why it lives here and not in the ruleset: no tool reports "this was sloppy". What tools report
are its symptoms, and those are rules — [Fail fast over fallback](./RULES.md#fail-fast-over-fallback),
[Illegal states unrepresentable](./RULES.md#illegal-states-unrepresentable), and the rest.

## Excuses that don't apply

These principles hold even when it feels like they shouldn't. None of the following is valid grounds for
skipping a rule, or for adding code that no requirement asked for:

- "It is just mock or test code that is not equally important, so I can disregard strictness."
- "This is just a prototype, I will add tests later."
- "These safeguards are usually needed, so I will add them here too."
- "Since this way of doing stuff is standard, I will follow it instead of being strict."
- "Following these guidelines would require a massive refactor."
- "Since I cannot find a way to avoid this code warning, I will mute it."
- "I can see guidelines are not followed in this codebase so it is not important I do."

The third is worth spelling out, because it is the one that looks like diligence rather than a shortcut.
The fallacy is generalizing a habit onto a case that has not been shown to need it: appending
[`|| true`](./RULES.md#no-suppressed-exit-status) or
[`2>/dev/null`](./RULES.md#no-discarded-diagnostics) to a command whose failure matters;
[catching an exception only to log it and continue](./RULES.md#no-silent-catch);
[branching on the platform](./RULES.md#no-speculative-portability) when the task fixes the platform;
[substituting a default](./RULES.md#no-default-to-satisfy-contract) when an input is missing instead of
stopping. Each one converts a loud, diagnosable failure into a silent wrong answer, which is the opposite
of failing fast. Add a safeguard when *this* path is shown to need it, and say what showed it.

---

See [`RULES.md`](./RULES.md) for the enforceable rules that operationalize this philosophy.

See [`WORKFLOW.md`](./WORKFLOW.md) for git and process rules.
