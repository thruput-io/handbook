# GITHUB ACCESS

1. Use exclusively `get-gh-token.sh` for GitHub access.

2. **Required Files.** The script expects exact secret files in `~/secrets/github`:
   - `~/secrets/github/client_id.txt`
   - `~/secrets/github/installation_id.txt`
   - `~/secrets/github/private_key.pem`

3. **The one form that runs.** Mint the token inline, unquoted, in the same command as `gh`:

       GH_TOKEN=$(get-gh-token.sh) gh <subcommand> <args>

   Every other spelling is refused before it executes. These are measured, not
   predicted, and retrying them wastes a turn:

   | Form                                                               | Result                                                              |
   |--------------------------------------------------------------------|---------------------------------------------------------------------|
   | `GH_TOKEN=$(get-gh-token.sh) gh ...`                               | runs                                                                |
   | `GH_TOKEN="$(get-gh-token.sh)" gh ...`                             | **refused** — the quotes stop the permission rule matching          |
   | `export GH_TOKEN="$(get-gh-token.sh)"`                             | **refused** — quoted or unquoted, `export` matches no rule          |
   | `export GH_TOKEN=...; gh ...`                                      | **refused** — the `export` half is refused, so the whole command is |
   | `git ... https://x-access-token:$(get-gh-token.sh)@github.com/...` | **refused** — a token embedded in a URL                             |
   | `GH_TOKEN=$(get-gh-token.sh) git ...`                              | **refused** — the rule covers `gh`, not `git`                       |

   The token cannot be carried between commands. There is no exported variable
   and no session state: mint it again in each command that needs it. A token
   lasts an hour, and minting is cheap.

4. **Token properties.**
   - **Installation token (`ghs_...`).** A GitHub App Installation Access Token, not a user account token.
   - **User endpoints fail.** `GET /user`, `gh auth status`, and `gh auth login` fail with `403 Resource not accessible by integration`. Use repository-scoped commands.
   - **`@me` fails.** `--assignee @me`, `--reviewer @me`, and `--web` fail the same way. Name a user or team explicitly or omit the flag.
   - **One hour.** Tokens expire after 60 minutes. Never store one.

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

6. **Never `cd` into a repository to run `git`.** Use `git -C`:

       git -C /Users/Shared/workspace/repo status --short     # runs
       cd /Users/Shared/workspace/repo && git status --short   # refused

   Entering a directory and running `git` there can execute that directory's
   hooks, so the combination requires approval and is refused outright. `git -C`
   is one command against a named repository and carries no such risk. Plain
   `git` in the directory you are already in is unaffected.

7. **Git over HTTPS is unresolved.** Authenticating `git pull` and `git push`
   against a remote has no working form: embedding the token in the URL is
   refused, and the `GH_TOKEN=` rule covers `gh` only. Reach for a `gh`
   subcommand where one exists. If a task needs `git push`, say so rather than
   working around it -- the gap is known and belongs to whoever maintains the
   permission rules.

8. **Never expose.** Never echo, log, print, or commit a token; never share it
   with another agent, process, or account; never read another account's token.
