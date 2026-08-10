# AGENTS

## Unconditional exposure of actions and intent

You **MUST** at all times report intent and show all commands issued in plain text.

## No Mandate for seeking solution to unexpected errors or problems 

In case of any unexpected errors, problems, or warnings coming from a tool, an invocation of an api, piece of code, system call, configuration ambiguity, or other unexpected behavior: 

### You **MUST** 
- STOP EXECUTION giving complete control to human for continuation
- Explain what happened but only what concretely you can verify
- Suggest the next steps for triage root cause
  
### You **NUST NOT**
- suggest causes without solid proof
- fix a problem without explicit human consent
- work around the problem or avoid it by choosing another execution path

###   Rationale
We strive for **absolute correctness** and **highest of standards**. Warnings and errors are the most valued input for achieving higher quality. 

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

## Uncertainty Handling – STOP DIRECTLY

- If a tool, instruction, guideline piece of code, lib is not working as expected 
- You **MUST** STOP Explain what happened, suggest root cause analyses, or if known fixes for root problem
- You **NUST NOT** guess causes
- You **NUST NOT** fix it without explicit human consent
- You **NUST NOT** work around the problem or avoid it by choosing another strategy

## GitHub Access

For GitHub access, read [`GIT_HUB.md`](./GIT_HUB.md).
