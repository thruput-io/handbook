# {NNN} — attempt {n} — {YYYY-MM-DD}

The progress log mandated by [`PLANNING.md § Progress logs`](./PLANNING.md#progress-logs). The
implementing agent copies it to `docs/plans/{plan-name}/progress/{NNN}-attempt-{n}-{YYYY-MM-DD}.md`
before the first change, where `{n}` is one higher than the highest attempt already in
`progress/`. Delete this paragraph and replace every `{placeholder}`.

|         |                                                                   |
|---------|-------------------------------------------------------------------|
| Plan    | `docs/plans/{plan-name}/{NNN}-{plan-name}.md`                     |
| Attempt | {n}                                                               |
| Branch  | `{NNN}-{plan-name}`                                               |
| Opened  | {YYYY-MM-DD}                                                      |
| Outcome | in progress \| complete \| abandoned — [PR]({url}) when abandoned |

## Rules for this file

- Append-only. **MUST NOT** rewrite, tidy, condense, or delete an entry once written. A
  correction is a new entry that names the entry it corrects.
- **MUST NOT** amend or force-push a commit that contains entries from this file.
- Commit each entry alongside the work it describes.
- Opening this file freezes the plan — see
  [`PLANNING.md § Reported progress freezes the plan`](./PLANNING.md#reported-progress-freezes-the-plan).
- If the attempt is abandoned, open a pull request carrying this log and state in the PR body
  what was attempted, where it broke, and what the next attempt should do differently. Do not
  delete the branch or this file.

## Entries

One entry per unit of work, newest last.

### {YYYY-MM-DD HH:MM} — {Milestone Mn}: {what was attempted}

- **Attempted:** {what was done}
- **Evidence:** {command run and what it showed, test name and result, file and line}
- **Decided:** {what was decided, and why}
- **Broke:** {what failed or was unexpected, or `nothing`}
