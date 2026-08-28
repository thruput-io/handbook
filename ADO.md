# AZURE DEVOPS & GIT GUIDELINES

## 1. Authentication Script (`get-ado-pat.sh`)

Use `/usr/local/bin/get-ado-pat.sh` for all Azure DevOps Git and CLI operations:

* **Raw PAT (`get-ado-pat.sh --raw`)**: Use for setting `AZURE_DEVOPS_EXT_PAT` environment variable with `az` CLI commands.
* **Base64 PAT (`get-ado-pat.sh --base64`)**: Outputs `x:<PAT>` base64-encoded. Use directly in Git HTTP header (`Authorization: Basic <base64>`).

---

## 2. Foreground Execution Mandatory

* **MUST NOT** run any `git` or `az` commands in the background.
* All `git` and `az` operations **MUST** be executed synchronously in the foreground.

---

## 3. Standard Command Patterns

### A. Git Push
```bash
git -c http.extraHeader="Authorization: Basic $(get-ado-pat.sh --base64)" push -u origin <branch-name>
```

### B. Git Pull / Fetch
```bash
git -c http.extraHeader="Authorization: Basic $(get-ado-pat.sh --base64)" pull
```

### C. Create Azure DevOps Pull Request
```bash
AZURE_DEVOPS_EXT_PAT=$(get-ado-pat.sh --raw) az repos pr create \
  --organization https://dev.azure.com/NavistarCollection/ \
  --project NavistarProduction \
  --repository <repo-name> \
  --source-branch <branch-name> \
  --target-branch main \
  --title "<title>" \
  --description "<body>" \
  --output table
```

### D. List Pull Requests
```bash
AZURE_DEVOPS_EXT_PAT=$(get-ado-pat.sh --raw) az repos pr list \
  --organization https://dev.azure.com/NavistarCollection/ \
  --project NavistarProduction \
  --repository <repo-name> \
  --output table
```


## DOTNET RESTORE

## Rule
To execute `dotnet restore`, `dotnet build`, or `dotnet test` against Azure DevOps Artifacts package feeds (`pkgs.dev.azure.com`) without interactive credential provider prompts or lock errors:

1. **Mint Raw PAT**: Use `PAT=$(get-ado-pat.sh --raw)`.
2. **Export Feed Credentials**: Set `VSS_NUGET_EXTERNAL_FEED_ENDPOINTS` environment variable with JSON payload mapping feed endpoints to `username: "az"` and `password: "$PAT"`.
3. **Set User `TMPDIR`**: Set `TMPDIR=/tmp/tore_tmp` to avoid system root lock permissions issues in `/tmp/NuGetScratch/lock/`.

---

## Standard Command Pattern

```bash
PAT=$(get-ado-pat.sh --raw)
FEED="https://pkgs.dev.azure.com/NavistarCollection/NavistarProduction/_packaging/DS-DD-DataIntegration-Common/nuget/v3/index.json"
export VSS_NUGET_EXTERNAL_FEED_ENDPOINTS="{\"endpointCredentials\": [{\"endpoint\": \"$FEED\", \"username\": \"az\", \"password\": \"$PAT\"}]}"
mkdir -p /tmp/tore_tmp
TMPDIR=/tmp/tore_tmp dotnet restore <project-path>
```
