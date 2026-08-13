# GITHUB ACCESS

1. Use exclusively `get-gh-token.sh` for GitHub access.

2. **Required Files.** The script expects exact secret files in `~/secrets/github`:
   - `~/secrets/github/client_id.txt`
   - `~/secrets/github/installation_id.txt`
   - `~/secrets/github/private_key.pem`

3. **Scope & Token Usage.** 

       export GH_TOKEN="$(get-gh-token.sh)"

   - **Installation Token (`ghs_...`):** The script returns a GitHub App Installation Access Token, not a user account token.
   - **User Endpoints Fail:** Endpoints expecting a GitHub user (such as `GET /user` or `gh auth status` / `gh auth login`) fail with `403 Resource not accessible by integration`. Use repository-scoped commands directly (e.g., `gh pr list -R owner/repo`).
   - **1-Hour Expiration:** Tokens expire after 60 minutes. Re-evaluate `export GH_TOKEN="..."` dynamically prior to tasks rather than storing static token strings.
   - **Git HTTPS Auth:** Use `x-access-token` as the username in HTTPS URLs (`git clone https://x-access-token:${GH_TOKEN}@github.com/owner/repo.git`).

4. **Sample Invocations.** Every example assumes the token was exported in the same shell first:

       export GH_TOKEN="$(get-gh-token.sh)"

   - **Pull.** Pass the authenticated URL for the one command instead of storing it in the remote, so an expired token never lingers in `.git/config`:

         git pull https://x-access-token:$(get-gh-token.sh)@github.com/owner/repo.git main
         npx skills install git+https://x-access-token:$(get-gh-token.sh)@github.com/thruput-io/skills.git/skills/pr-review

   - **Create a pull request.** Name the repository with `-R` and the source branch with `--head`; `gh` cannot fall back on the current user to resolve either:

         gh pr create -R owner/repo --base main --head my-branch \
           --title "Short summary" --body "What changed and why."

   - `--assignee @me`, `--reviewer @me`, and `--web` fail with `403 Resource not accessible by integration`. Name a user or team explicitly, or omit the flag.

5. **Never expose.** Never echo, log, print, or commit a token; never share it with another agent, process, or account; never read another account's token.
