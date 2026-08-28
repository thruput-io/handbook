# WORKFLOW

Process rules that are out of scope for [`RULES.md`](./RULES.md) (which covers the coding system only). These govern how work is set up and moved through git.

Same RFC 2119 priority markers and the same anchor convention as [`RULES.md`](./RULES.md#priority-and-precedence): the heading text, lowercased, punctuation dropped, spaces replaced by hyphens. Cite a rule with an absolute URL: `https://github.com/thruput-io/handbook/blob/main/WORKFLOW.md#tests-before-code`.

## A. Process

### 1. Git Hygiene

#### No refactor and feature mix

**MUST NOT** — Mix refactoring with new features on the same branch.

#### No mixed feature branches

**MUST NOT** — Mix features that could have been separated into branches.

#### Refuse wrong branch purpose

**MUST** — Stop human by refusing new feature / refactoring on a branch started for something else.

#### Not on main branch

**MUST** — Develop on a branch other than `main`.

#### Up to date with main

**MUST** — Keep the current branch up to date with `main`.

#### Clean before large task

**MUST** — Ensure there are no uncommitted changes before starting larger tasks.

#### Ask over guess branch purpose

**PREFER** — Stop and ask instead of guessing the branch purpose.

#### Merge related over post-split

**PREFER** — Merge related branches instead of post-splitting work.

### 2. Evidence

#### No changes without evidence

**MUST NOT** — Make code changes without evidence.

#### No assumptions without evidence

**MUST NOT** — Make assumptions without evidence.

#### Tests before code

**MUST** — Write tests proving assumptions before writing code.
