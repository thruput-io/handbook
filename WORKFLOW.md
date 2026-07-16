# WORKFLOW

Process rules that are out of scope for [`RULES.md`](./RULES.md) (which covers the coding system only). These govern how work is set up and moved through git.

Same RFC 2119 priority markers as `RULES.md`. Each rule has a short human-readable heading and a stable HTML anchor id like `workflow-git-hygiene-no-refactor-feature-mix`.

## A. Process

### 1. Git Hygiene

#### No refactor + feature mix <a id="workflow-git-hygiene-no-refactor-feature-mix"></a>

**MUST NOT** — Mix refactoring with new features on the same branch.

#### No mixed feature branches <a id="workflow-git-hygiene-no-mixed-feature-branches"></a>

**MUST NOT** — Mix features that could have been separated into branches.

#### Refuse wrong branch purpose <a id="workflow-git-hygiene-refuse-wrong-branch-purpose"></a>

**MUST** — Stop human by refusing new feature / refactoring on a branch started for something else.

#### Not on main branch <a id="workflow-git-hygiene-not-main-branch"></a>

**MUST** — Develop on a branch other than `main`.

#### Up to date with main <a id="workflow-git-hygiene-up-to-date-with-main"></a>

**MUST** — Keep the current branch up to date with `main`.

#### Clean before large task <a id="workflow-git-hygiene-clean-before-large-task"></a>

**MUST** — Ensure there are no uncommitted changes before starting larger tasks.

#### Ask over guess branch purpose <a id="workflow-git-hygiene-ask-over-guess-branch-purpose"></a>

**PREFER** — Stop and ask instead of guessing the branch purpose.

#### Merge related over post-split <a id="workflow-git-hygiene-merge-related-branches-over-post-split"></a>

**PREFER** — Merge related branches instead of post-splitting work.

### 2. Evidence

#### No changes without evidence <a id="workflow-evidence-no-changes-without-evidence"></a>

**MUST NOT** — Make code changes without evidence.

#### No assumptions without evidence <a id="workflow-evidence-no-assumptions-without-evidence"></a>

**MUST NOT** — Make assumptions without evidence.

#### Tests before code <a id="workflow-evidence-tests-before-code"></a>

**MUST** — Write tests proving assumptions before writing code.

#### Platform tests over later <a id="workflow-evidence-platform-tests-over-later"></a>

**PREFER** — Pin assumptions by 'platform' or 'framework' tests over waiting until later.

#### Risk assumptions in plan <a id="workflow-evidence-risk-assumptions-in-plan"></a>

**PREFER** — Add a test assumptions section to any plan with risk.
