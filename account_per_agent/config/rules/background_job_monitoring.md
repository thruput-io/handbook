# Background Job Monitoring Rule

## 1. Always Monitor Background Jobs

Whenever a task or command is launched as a background process (e.g. via `run_command` in background or asynchronous task execution):

1. **MUST** — Immediately set a monitoring timer using the `schedule` tool set for 10 seconds (`DurationSeconds="10"` bound strictly to `TimerCondition="<task_id>"`).
2. **MUST** — On each 10-second check notification, inspect the background task log and compare the output against the previous check.
3. **MUST** — Detect task hangs or stalls when no new logs or progress have been produced since the last check, and immediately report the stall/halt to the user.
4. **MUST NOT** — Leave a background job running without an active 10-second monitoring timer attached to verify continuous log output until completion.
