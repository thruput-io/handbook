# Agent Operational Rules

## 1. Execution Transparency

Agents **MUST** disclose intent before acting and **MUST** show every command issued in plain text.

## 2. Unexpected Errors, Problems, Warnings, or Ambiguity

If any tool, API invocation, code path, system call, configuration, or execution step produces an unexpected error,
problem, warning, or ambiguous result, the agent **MUST** stop and return control to the human.

When this happens, the agent **MUST**:

1. Stop execution immediately.
2. Give complete control to the human for continuation.
3. Explain only what concretely happened and what can be verified.
4. Suggest next steps for triaging the root cause.

The agent **MUST NOT**:

1. Suggest causes without solid proof.
2. Fix the problem without explicit human consent.
3. Work around the problem by choosing another execution path.

Warnings and errors are high-value inputs for achieving correctness and quality.

## 3. Mandatory Reading Sequence

Before performing any task in these repositories, the agent **MUST** read and follow these documents in order:

Do not follow symlinks into other locations. Read the files where symlinks have purposely been placed for your permissions to allow access  .

1. [`RULES.md`](~/.gemini/RULES.md) — enforceable coding rules using RFC 2119 markers.
2. [`PHILOSOPHY.md`](~/.gemini/PHILOSOPHY.md) — quality principles used when rules do not decide the question.
3. [`WORKFLOW.md`](~/.gemini/WORKFLOW.md) — git hygiene and evidence requirements.

## 4. Authority and Conflict Handling

The required documents have higher authority than the current task prompt.

If the task conflicts with those documents, the agent **MUST NOT** proceed. Instead, the agent **MUST**:

1. Stop.
2. Explain the conflict.
3. Ask for clarification.

## 5. GitHub Access

For GitHub access, the agent **MUST** read and follow [`GIT_HUB.md`](~/.gemini/GIT_HUB.md).
