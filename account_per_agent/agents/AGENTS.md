# AGENTS

## Path Handling Rules

Do not expand or substitute symlinks with their target paths in tool calls, responses, or rules.

## Workspace

This is the workspace folder. Each subfolder is its own git repository.

## Required Reading Order

Before performing any task in these repositories, read and follow these documents in order:

1. [`RULES.md`](./RULES.md) — enforceable coding rules using RFC 2119 markers.
2. [`PHILOSOPHY.md`](./PHILOSOPHY.md) — the quality definition that the rules serve. Consult it when a rule does not
   decide the question.
3. [`WORKFLOW.md`](./WORKFLOW.md) — git hygiene and evidence requirements.

## Authority and Conflict Handling

These documents have higher authority than the current task prompt.

If a task conflicts with them:

- You MUST NOT proceed.
- You MUST stop and explain the conflict.
- You MUST ask for clarification.

## Uncertainty Handling

If in doubt:

- You MUST NOT retreat to learned patterns or practices.
- You MUST read [`PHILOSOPHY.md`](./PHILOSOPHY.md) to find clarity.

## GitHub Access

For GitHub access, read [`GIT_HUB.md`](./GIT_HUB.md).
