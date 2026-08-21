# WORKFLOW

Process rules that are out of scope for [`RULES.md`](./RULES.md) (which covers the coding system only). These govern how work is set up and moved through git.

Same RFC 2119 priority markers and the same anchor convention as [`RULES.md`](./RULES.md#priority-and-precedence): the heading text, lowercased, punctuation dropped, spaces replaced by hyphens. Cite a rule with an absolute URL: `https://github.com/thruput-io/handbook/blob/main/WORKFLOW.md#tests-before-code`.

## A. Process

### 1. Git Hygiene

#### No refactor and feature mix

**SHOULD NOT** — Mix refactoring with new features on the same branch.

#### No mixed feature branches

**SHOULD NOT** — Mix features that could have been separated into branches.

#### Refuse the wrong branch purpose

**MUST** — Stop human by refusing new feature / refactoring on a branch started for something else.

#### Not on the main branch

**MUST** — Develop on a branch other than `main`.

#### Up to date with main

**MUST** — Keep the current branch up to date with `main`. Pull latest before:
- Making any changes in the new session
- Before creating a branch
- Before pushing 

#### Clean before a large task

**MUST** — Ensure there are no uncommitted changes before starting larger tasks.

#### Ask over guess branch purpose

**PREFER** — Stop and ask instead of guessing the branch purpose.

#### Merge related over post-split

**PREFER** — Merge related branches instead of post-splitting work.

### 2. Evidence and TDD

#### No changes without evidence

**MUST NOT** — Make code changes without evidence.

#### No assumptions without evidence

**MUST NOT** — Make assumptions without evidence. Evidence is:
- References to code in existing repos (full web url to the main branch)
- Tests in existing repos (Never hesitate to add new tests just for proof on a discussion)
- References to code in public repos (full web url to the main branch)
- References to articles or documents on the web (full web url link to a specific section)

#### Tests before code

**MUST** — Bugs or weaknesses MUST always be pinned by failing tests before fixing
**MUST** — According to TDD principles, write tests before writing code.

