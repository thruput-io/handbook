# GITHUB ACCESS

1. **Location.** [`get-gh-token.sh`](./get-gh-token.sh) MUST live at — or be symlinked to — `~/.gemini/antigravity-cli/bin/get-gh-token.sh`.

2. **Required Files.** The script expects exact secret files in `~/secrets/github`:
   - `~/secrets/github/client_id.txt`
   - `~/secrets/github/installation_id.txt`
   - `~/secrets/github/private_key.pem`

3. **Scope.** Use exclusively `get-gh-token.sh` for GitHub access:

       export GH_TOKEN="$(~/.gemini/antigravity-cli/bin/get-gh-token.sh)"

4. **Never expose.** Never echo, log, print, or commit a token; never share it with another agent, process, or account; never read another account's token.
