#!/usr/bin/env bash
set -euo pipefail

# Emits this account's Anthropic API key on stdout, for Claude Code's
# apiKeyHelper setting. Runs as the agent, so $HOME is the agent's own.
#
# Claude Code keeps a /login credential in the macOS Keychain, which an agent
# account can never reach: `sudo -i -u <agent>` starts no GUI login session, so
# that account's login keychain is never unlocked and does not even appear in
# its keychain search list. Left to /login, every agent throws a browser and a
# keychain dialog into the admin owner's GUI session and authenticates as
# whoever answers it.
#
# A key under the agent's own secrets directory avoids the Keychain entirely
# and keeps each agent a distinct API identity, revocable on its own.

# Deliberately not under ~/secrets. That directory is the agent process's own
# working store -- it reads GitHub credentials from there during normal work, so
# it is inside the surface the agent browses. This key is different in kind: it
# authenticates the runtime itself, is never an input to the agent's work, and
# has no reason to sit where the agent looks. Keeping it out means settings.json
# can deny reads here without also cutting the agent off from the secrets it is
# supposed to use.
KEY_FILE="$HOME/anthropic-api-key/api_key.txt"

if [[ ! -r "${KEY_FILE}" ]]; then
  echo "No Anthropic API key for ${USER:-$(id -un)} at ${KEY_FILE}" >&2
  exit 1
fi

# tr, not cat: an editor leaves a trailing newline and the API rejects a key
# sent with surrounding whitespace.
KEY="$(tr -d '\r\n ' < "${KEY_FILE}")"

if [[ -z "${KEY}" ]]; then
  echo "Anthropic API key file is empty: ${KEY_FILE}" >&2
  exit 1
fi

printf '%s' "${KEY}"
