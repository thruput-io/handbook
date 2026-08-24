# AZ CHEAT SHEET

Exact `az` invocations for reviewing an **Azure DevOps** pull request. Counterpart to [`gh-cheat-sheet.md`](./gh-cheat-sheet.md): syntax only, no rules. Referenced by [`CODE_REVIEW.md`](./CODE_REVIEW.md) and [`PROBE_SUBAGENT_TEMPLATE.md`](./PROBE_SUBAGENT_TEMPLATE.md), which own the rules; where a command here would contradict them, the rule wins.

Requires the `azure-devops` extension (`az extension add --name azure-devops`).

Placeholders, all readable off the PR URL
`https://dev.azure.com/{org}/{project}/_git/{repo}/pullrequest/{id}`:

| Placeholder | Meaning                                                                       |
|-------------|-------------------------------------------------------------------------------|
| `{org}`     | `https://dev.azure.com/NavistarCollection` — the full URL, not the bare name  |
| `{project}` | e.g. `NavistarProduction`                                                     |
| `{repoId}`  | repository **GUID**, from the PR overview; the name also works in most routes |
| `{id}`      | PR number, e.g. `51964`                                                       |
| `{sha}`     | `lastMergeSourceCommit.commitId` — the head commit, GitHub's `headRefOid`     |

Pass `--org {org} --detect false` on every command. Without `--detect false` the CLI tries to infer org and project from the git remote of the current directory, which is wrong whenever the review runs outside a checkout of that repo.

## Availability

`az` must be available, with the `azure-devops` extension installed. `az version` reports both.

Auth is either `az login` or a PAT in `AZURE_DEVOPS_EXT_PAT`.

## Read a pull request

Overview, reduced to the fields a review needs:

```bash
az repos pr show --id {id} --org {org} --detect false \
  --query '{id:pullRequestId, title:title, description:description, status:status,
            isDraft:isDraft, author:createdBy.uniqueName,
            source:sourceRefName, target:targetRefName, mergeStatus:mergeStatus,
            headCommit:lastMergeSourceCommit.commitId,
            baseCommit:lastMergeTargetCommit.commitId,
            repoId:repository.id, project:repository.project.name}'
```

`headCommit` is the head SHA every subsequent command anchors to. `mergeStatus` is `succeeded` when the PR has no conflicts — `conflicts` is the merge-conflict signal.

| Purpose                               | Command                                                                                                                                                                        |
|---------------------------------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| List active PRs                       | `az repos pr list --status active --org {org} --detect false -o table`                                                                                                         |
| Branch policies (the checks analogue) | `az repos pr policy list --id {id} --org {org} --detect false --query '[].{policy:configuration.type.displayName, status:status, blocking:configuration.isBlocking}' -o table` |
| Reviewers and their votes             | `az repos pr reviewer list --id {id} --org {org} --detect false --query '[].{name:displayName, vote:vote}' -o table`                                                           |

Policy `status` is `approved`, `queued`, `running`, or `rejected`. A blocking policy that is not `approved` is the Azure DevOps equivalent of a failing check.

Votes are integers: `10` approved, `5` approved with suggestions, `0` no vote, `-5` waiting for author, `-10` rejected.

## Changed files

Azure DevOps scopes changes to an **iteration** (one per push). Take the last iteration:

```bash
az devops invoke --area git --resource pullRequestIterations \
  --route-parameters project={project} repositoryId={repoId} pullRequestId={id} \
  --org {org} --api-version 7.1 --query 'value[-1].id' -o tsv
```

Then it changed paths:

```bash
az devops invoke --area git --resource pullRequestIterationChanges \
  --route-parameters project={project} repositoryId={repoId} pullRequestId={id} iterationId={iteration} \
  --org {org} --api-version 7.1 \
  --query 'changeEntries[].{path:item.path, change:changeType}' -o table
```

Paths are repository-absolute and begin with `/`.

## Read files at the head commit

There is no `az` command that returns a textual diff. Fetch whole files and compare, which is what [`CODE_REVIEW.md` § Read beyond the diff](./CODE_REVIEW.md#1-setup) requires anyway:

```bash
az devops invoke --area git --resource items \
  --route-parameters project={project} repositoryId={repoId} \
  --query-parameters path={path} versionDescriptor.version={sha} \
                    versionDescriptor.versionType=commit includeContent=true \
  --org {org} --api-version 7.1 --query content -o tsv
```

Or clone and read locally — often cheaper for a multi-file review:

```bash
git clone --branch {sourceBranch} https://dev.azure.com/{org-name}/{project}/_git/{repo}
```

## Existing comment threads

```bash
az devops invoke --area git --resource pullRequestThreads \
  --route-parameters project={project} repositoryId={repoId} pullRequestId={id} \
  --org {org} --api-version 7.1 \
  --query 'value[?comments[0].commentType==`text`].{id:id, status:status,
            path:threadContext.filePath, line:threadContext.rightFileStart.line,
            body:comments[0].content}'
```

The `commentType==text` filter matters: Azure DevOps stores its own activity as threads too ("Policy status has been updated", "set auto-complete", reference-updated notices). Those come back with `commentType: system` and a null `threadContext`, and counting them as review comments will corrupt a duplicate check.

Thread `status` values: `active`, `fixed`, `wontFix`, `closed`, `pending`, `byDesign`.

## Post an inline comment thread

One POST per thread. Body in a file, e.g. `thread.json`:

```json
{
  "comments": [
    {
      "parentCommentId": 0,
      "commentType": "text",
      "content": "[No suppressed exit status](https://github.com/thruput-io/handbook/blob/main/RULES.md#no-suppressed-exit-status): what is wrong, briefly."
    }
  ],
  "status": "active",
  "threadContext": {
    "filePath": "/terraform/main.tf",
    "rightFileStart": { "line": 42, "offset": 1 },
    "rightFileEnd": { "line": 42, "offset": 1 }
  }
}
```

```bash
az devops invoke --area git --resource pullRequestThreads \
  --route-parameters project={project} repositoryId={repoId} pullRequestId={id} \
  --org {org} --api-version 7.1 --http-method POST --in-file thread.json
```

- `filePath` is repository-absolute, leading `/`, as returned by the iteration changes.
- `rightFileStart`/`rightFileEnd` anchor to the head-commit side. Use `leftFileStart`/`leftFileEnd` for a removed line — the equivalent of GitHub's `side: LEFT`.
- `offset` is a 1-based **column**. Azure DevOps requires it; GitHub has no equivalent.
- Omit `threadContext` entirely for a PR-level (non-inline) comment.

Update a thread's status — the resolve/unresolve equivalent — with `--http-method PATCH`, route parameter `threadId={threadId}`, and body `{"status": "fixed"}` or `{"status": "active"}`.

## Vote

```bash
az repos pr set-vote --id {id} --vote approve --org {org} --detect false
```

`--vote` takes `approve`, `approve-with-suggestions`, `wait-for-author`, `reject`, or `reset`.

## No atomic review

This is the one place the Azure DevOps model does not fit [`CODE_REVIEW.md` step 7](./CODE_REVIEW.md#7-submit). GitHub accepts one payload carrying every inline comment plus the verdict, producing one review and one notification. Azure DevOps has no such endpoint: each thread is its own POST and the vote is a separate call. N comments therefore mean N requests and N notifications, and there is no way to make them atomic.

Consequences for a review run against Azure DevOps:

- Draft all comments locally first, exactly as step 5 says, and post only after the ledger is complete. The local draft is what replaces atomicity.
- Post every thread **before** casting the vote, so the verdict never lands ahead of its evidence.
- A failure partway through leaves the PR with some threads posted. Re running must not duplicate them — reconcile against existing threads first.

## Verification status

Every read command above was executed against a live PR (`NavistarCollection/NavistarProduction`, PR 51964) and returned the documented shape.

The writing paths — thread POST, thread PATCH, `set-vote` — are documented from the REST API and were **not** executed, to avoid posting to a real pull request. Confirm the payload against a scratch PR before trusting it.
