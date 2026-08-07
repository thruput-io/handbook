# GITHUB ACCESS

1. **Location.** [`get-gh-token.sh`](./get-gh-token.sh) MUST live at — or be symlinked to — `~/.gemini/antigravity-cli/bin/get-gh-token.sh`.

2. **Scope.**  Use exclusively get-gh-token.sh for GitHub access. 

       export GH_TOKEN="$(~/.gemini/antigravity-cli/bin/get-gh-token.sh)"

3. **Cache.** The token is always cached in `~/secrets/created_by_agent` at mode `600`, and nowhere else.

4. **Never expose.** Never echo, log, print, or commit a token; never share it with another agent, process, or account; never read another account's token.
