# GITHUB ACCESS

1. Use exclusively `get-gh-token.sh` for GitHub access.

2. **Required Files.** The script expects exact secret files in `~/secrets/github`:
   - `~/secrets/github/client_id.txt`
   - `~/secrets/github/installation_id.txt`
   - `~/secrets/github/private_key.pem`

3. **The one form that runs.** Mint the token inline, unquoted, in the same command as `gh`:

   The token cannot be carried between commands. There is no exported variable
   and no session state: mint it again in each command that needs it. A token
   lasts an hour, and minting is cheap.

4. **Token properties.**
   - **Installation token (`ghs_...`).** A GitHub App Installation Access Token, not a user account token.
   - **User endpoints fail.** `GET /user`, `gh auth status`, and `gh auth login` fail with `403 Resource not accessible by integration`. Use repository-scoped commands.
   - **`@me` fails.** `--assignee @me`, `--reviewer @me`, and `--web` fail the same way. Name a user or team explicitly or omit the flag.
   - **One hour.** Tokens expire after 60 minutes. Always store in ~/secrets/created_by_agent folder

5. **Sample invocations.**

   - **Read repository data.**

         GH_TOKEN=$(get-gh-token.sh) gh api repos/owner/repo --jq .default_branch
         GH_TOKEN=$(get-gh-token.sh) gh pr list -R owner/repo --limit 10
         GH_TOKEN=$(get-gh-token.sh) gh pr view 14 -R owner/repo --json number,state,title

   - **Clone.** Use `gh repo clone` rather than a `git clone` URL carrying a token:

         GH_TOKEN=$(get-gh-token.sh) gh repo clone owner/repo ~/workspace/repo

   - **Create a pull request.** Name the repository with `-R` and the source branch
     with `--head`; `gh` cannot fall back on the current user to resolve either:

         GH_TOKEN=$(get-gh-token.sh) gh pr create -R owner/repo --base main --head my-branch \
           --title "Short summary" --body "What changed and why."

6. **Never expose.** Never echo, log, print, or commit a token; never share it
   with another agent, process, or account; never read another account's token.
