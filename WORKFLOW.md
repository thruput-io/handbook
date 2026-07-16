# WORKFLOW

Process rules that are out of scope for [`RULES.md`](./RULES.md) (which covers the coding system only). These govern how work is set up and moved through git.

Same RFC 2119 priority markers as `RULES.md`.

## 1. Git Hygiene

— **MUST NOT** [@Workflow.GitHygiene.NoRefactorFeatureMix]
  — Mix refactoring with new features on the same branch.

— **MUST NOT** [@Workflow.GitHygiene.NoMixedFeatureBranches]
  — Mix features that could have been separated into branches.

— **MUST** [@Workflow.GitHygiene.RefuseWrongBranchPurpose]
  — Stop human by refusing new feature / refactoring on a branch started for something else.

— **MUST** [@Workflow.GitHygiene.NotMainBranch]
  — Develop on a branch other than `main`.

— **MUST** [@Workflow.GitHygiene.UpToDateWithMain]
  — Keep the current branch up to date with `main`.

— **MUST** [@Workflow.GitHygiene.CleanBeforeLargeTask]
  — Ensure there are no uncommitted changes before starting larger tasks.

— **PREFER** [@Workflow.GitHygiene.AskOverGuessBranchPurpose]
  — Stop and ask instead of guessing the branch purpose.

— **PREFER** [@Workflow.GitHygiene.MergeRelatedBranchesOverPostSplit]
  — Merge related branches instead of post-splitting work.

## 2. Evidence

— **MUST NOT** [@Workflow.Evidence.NoChangesWithoutEvidence]
  — Make code changes without evidence.

— **MUST NOT** [@Workflow.Evidence.NoAssumptionsWithoutEvidence]
  — Make assumptions without evidence.

— **MUST** [@Workflow.Evidence.TestsBeforeCode]
  — Write tests proving assumptions before writing code.

— **PREFER** [@Workflow.Evidence.PlatformTestsOverLater]
  — Pin assumptions by 'platform' or 'framework' tests over waiting until later.

— **PREFER** [@Workflow.Evidence.RiskAssumptionsInPlan]
  — Add a test assumptions section to any plan with risk.
