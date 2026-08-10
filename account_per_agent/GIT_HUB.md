# GITHUB ACCESS

1. **Location.** [`get-gh-token.sh`](./get-gh-token.sh) MUST live at — or be symlinked to — `~/.gemini/antigravity-cli/bin/get-gh-token.sh`.

2. **Required Files.** The script expects exact secret files in `~/secrets/github`:
   - `~/secrets/github/client_id.txt`
   - `~/secrets/github/installation_id.txt`
   - `~/secrets/github/private_key.pem`

3. **Scope & Token Usage.** Use exclusively `get-gh-token.sh` for GitHub access:

       export GH_TOKEN="$(~/.gemini/antigravity-cli/bin/get-gh-token.sh)"

   - **Installation Token (`ghs_...`):** The script returns a GitHub App Installation Access Token, not a user account token.
   - **User Endpoints Fail:** Endpoints expecting a GitHub user (such as `GET /user` or `gh auth status` / `gh auth login`) fail with `403 Resource not accessible by integration`. Use repository-scoped commands directly (e.g., `gh pr list -R owner/repo`).
   - **1-Hour Expiration:** Tokens expire after 60 minutes. Re-evaluate `export GH_TOKEN="..."` dynamically prior to tasks rather than storing static token strings.
   - **Git HTTPS Auth:** Use `x-access-token` as the username in HTTPS URLs (`git clone https://x-access-token:${GH_TOKEN}@github.com/owner/repo.git`).

4. **Never expose.** Never echo, log, print, or commit a token; never share it with another agent, process, or account; never read another account's token.
