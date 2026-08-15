#!/usr/bin/env bash
set -uo pipefail

# Verifies everything install_claude_shared.sh and setup_claude.sh put in
# place, from the perspective that matters: what each agent account can
# actually reach and actually do.
#
# Deliberately NOT set -e, and deliberately not fail-fast. A verifier that
# aborts on the first failed check hides every other broken thing, which is
# the opposite of useful when something has drifted. Every check runs, the
# summary reports totals, and the exit status is non-zero if any check failed.
#
# Read-only apart from two probes, each of which cleans up after itself:
#
#   Section 6 creates a root-owned canary symlink and tries to remove it as the
#   agent. The real rule links are never touched -- deleting those would destroy
#   the configuration precisely when the protection is broken, the one moment a
#   verifier must not make things worse. The canary sits in the same directory
#   with the same ownership, so the unlink rules that apply to it are the rules
#   that apply to them.
#
#   Section 9 creates and removes a file in the shared workspace, because an
#   agent that cannot write there is broken however correct its modes look.
#
# Key material is never captured. Section 8 checks the key file by metadata
# only -- mode and owner, never opened. Section 9 does open it, since being
# readable by its own account is the file's whole purpose and only a real read
# exercises that; every read is redirected to /dev/null, so no key is printed,
# logged, or held in a variable, in either the positive or the negative case.
#
# Both sections name the key path, which discloses its location to anyone
# reading this script. Accepted deliberately: the path is already in
# settings.json and the helper, and naming it here is what lets a failure say
# which of mode or owner is wrong rather than only that access broke.

if [[ -t 1 ]]; then
  C_OK=$'\033[32m'; C_BAD=$'\033[31m'; C_WARN=$'\033[33m'; C_HEAD=$'\033[1m'; C_OFF=$'\033[0m'
else
  C_OK=""; C_BAD=""; C_WARN=""; C_HEAD=""; C_OFF=""
fi

PASS=0
FAIL=0
WARN=0

ok()   { printf "  ${C_OK}PASS${C_OFF}  %s\n" "$*"; PASS=$((PASS + 1)); }
bad()  { printf "  ${C_BAD}FAIL${C_OFF}  %s\n" "$*"; FAIL=$((FAIL + 1)); }
# Not-yet-provisioned is not the same as misconfigured: a missing credential is
# work outstanding, a wrong mode on one that exists is a defect. Warnings are
# reported but do not fail the run.
warn() { printf "  ${C_WARN}WARN${C_OFF}  %s\n" "$*"; WARN=$((WARN + 1)); }
section() { printf "\n${C_HEAD}%s${C_OFF}\n" "$*"; }
note() { printf "        %s\n" "$*"; }

# Report the outcome of a command as a check. Output is discarded; only the
# exit status decides.
check() {
  local desc="$1"
  shift
  if "$@" >/dev/null 2>&1; then ok "${desc}"; else bad "${desc}"; fi
}

# Everything an agent is asked to do runs through this.
#
# -H is essential: sudo preserves HOME by default, so without it a command run
# as an agent still points at the invoking user's home, and every ~-relative
# check silently tests the wrong account.
#
# A login zsh, not sh, and not a bare zsh. PATH reaches the agents through
# path_helper, which runs from /etc/zprofile and therefore only in a login
# shell; DISABLE_AUTOUPDATER reaches them from /etc/zshenv, which sh never
# reads at all. Under /bin/sh both come back empty and the verifier reports
# failures against a configuration that is in fact correct -- it would be
# testing a shell no agent ever gets.
as_user() {
  local user="$1"
  shift
  sudo -n -H -u "${user}" /bin/zsh -lc "$*"
}

OS_NAME="$(uname -s)"
case "${OS_NAME}" in
  Darwin) BASE_DIR="/Users"; DEFAULT_ADMINS_GROUP="admin" ;;
  Linux)  BASE_DIR="/home";  DEFAULT_ADMINS_GROUP="sudo" ;;
  *) echo "Unsupported platform: ${OS_NAME}" >&2; exit 2 ;;
esac
BASE_DIR="${AGENT_HOME_BASE:-${BASE_DIR}}"

DEVELOPERS_GROUP="${DEVELOPERS_GROUP:-developers}"
ADMINS_GROUP="${ADMINS_GROUP:-${DEFAULT_ADMINS_GROUP}}"
SHARED_ROOT="${CLAUDE_SHARED_ROOT:-/Users/Shared/tools/claude}"
SHARED_BIN_DIR="${SHARED_ROOT}/bin"
SHARED_BIN="${SHARED_BIN_DIR}/claude"
SHARED_WORKSPACE="${SHARED_WORKSPACE:-/Users/Shared/workspace}"

HANDBOOK_DOCS=("RULES.md" "PHILOSOPHY.md" "WORKFLOW.md" "GIT_HUB.md")
RULES_ROOT_DOC="CLAUDE.md"

user_in_group() { id -Gn "$1" 2>/dev/null | tr ' ' '\n' | grep -qx "$2"; }

list_all_users() {
  case "${OS_NAME}" in
    Darwin) dscl . -list /Users 2>/dev/null ;;
    Linux)  getent passwd | cut -d: -f1 ;;
  esac
}

# Same derivation as setup.sh and setup_claude.sh, so the verifier checks the
# same accounts the provisioners acted on rather than a hardcoded list that
# could drift away from them.
resolve_identities() {
  local user admins="" agents=""

  for user in $(list_all_users); do
    user_in_group "${user}" "${DEVELOPERS_GROUP}" || continue
    if user_in_group "${user}" "${ADMINS_GROUP}"; then
      admins="${admins:+${admins} }${user}"
    else
      agents="${agents:+${agents} }${user}"
    fi
  done

  ADMIN_OWNER="${ADMIN_OWNER:-${admins}}"
  AGENTS="${AGENTS:-${agents}}"

  if [[ -z "${ADMIN_OWNER}" || "${ADMIN_OWNER}" == *" "* ]]; then
    echo "Cannot resolve a single admin owner (got: '${ADMIN_OWNER}'); set ADMIN_OWNER" >&2
    exit 2
  fi
  if [[ -z "${AGENTS}" ]]; then
    echo "No agent accounts found; set AGENTS" >&2
    exit 2
  fi
}

# Mode and owner:group of a path, without following symlinks.
#
# %Mp%Lp, not %Lp: the latter reports only the low permission bits and drops
# setgid and sticky entirely, so 2750 reads back as 750 and 1775 as 775 -- the
# two bits this setup depends on most would go unverified while appearing to
# fail.
stat_mode()  { sudo stat -f '%Mp%Lp' "$1" 2>/dev/null; }
stat_owner() { sudo stat -f '%Su:%Sg' "$1" 2>/dev/null; }

resolve_identities
read -r -a AGENT_NAMES <<<"${AGENTS}"

printf "${C_HEAD}Claude Code fleet verification${C_OFF}\n"
note "admin owner : ${ADMIN_OWNER}"
note "agents      : ${AGENTS}"

# --- 1. shared binary ------------------------------------------------------
section "1. Shared binary"

check "binary exists at ${SHARED_BIN}" test -f "${SHARED_BIN}"
check "binary is executable" test -x "${SHARED_BIN}"

BIN_OWNER="$(stat_owner "${SHARED_BIN}")"
if [[ "${BIN_OWNER}" == "${ADMIN_OWNER}:${DEVELOPERS_GROUP}" ]]; then
  ok "binary owned by ${ADMIN_OWNER}:${DEVELOPERS_GROUP}"
else
  bad "binary owner is '${BIN_OWNER}', expected '${ADMIN_OWNER}:${DEVELOPERS_GROUP}'"
fi

# 0750, not 750: stat_mode prepends the high bits, which are zero on a plain
# file and 2 on the setgid directory below.
BIN_MODE="$(stat_mode "${SHARED_BIN}")"
if [[ "${BIN_MODE}" == "0750" ]]; then
  ok "binary mode 0750 (agents read+execute, no write)"
else
  bad "binary mode is ${BIN_MODE}, expected 0750"
fi

DIR_MODE="$(stat_mode "${SHARED_BIN_DIR}")"
if [[ "${DIR_MODE}" == "2750" ]]; then
  ok "bin directory mode 2750"
else
  bad "bin directory mode is ${DIR_MODE}, expected 2750"
fi

# --- 2. PATH registration --------------------------------------------------
section "2. PATH registration"

check "/etc/paths.d/claude exists" test -f /etc/paths.d/claude

if [[ "$(cat /etc/paths.d/claude 2>/dev/null)" == "${SHARED_BIN_DIR}" ]]; then
  ok "/etc/paths.d/claude points at ${SHARED_BIN_DIR}"
else
  bad "/etc/paths.d/claude content is '$(cat /etc/paths.d/claude 2>/dev/null)'"
fi

# path_helper performs no expansion, so a ~ in any drop-in silently yields a
# PATH entry that resolves to nothing.
if grep -l '~' /etc/paths.d/* >/dev/null 2>&1; then
  bad "a /etc/paths.d entry contains '~' (path_helper does not expand it): $(grep -l '~' /etc/paths.d/* | tr '\n' ' ')"
else
  ok "no /etc/paths.d entry relies on ~ expansion"
fi

# --- 3. resolution and version parity --------------------------------------
section "3. Resolution and version parity"

REF_VERSION=""
for user in "${ADMIN_OWNER}" "${AGENT_NAMES[@]}"; do
  resolved="$(as_user "${user}" 'command -v claude' 2>/dev/null)"
  if [[ "${resolved}" == "${SHARED_BIN}" ]]; then
    ok "${user}: claude resolves to the shared binary"
  else
    bad "${user}: claude resolves to '${resolved:-<not found>}'"
    continue
  fi

  version="$(as_user "${user}" 'claude --version' 2>/dev/null | /usr/bin/head -1)"
  if [[ -z "${REF_VERSION}" ]]; then
    REF_VERSION="${version}"
    note "reference version: ${REF_VERSION}"
  elif [[ "${version}" != "${REF_VERSION}" ]]; then
    bad "${user}: version '${version}' differs from '${REF_VERSION}'"
  fi
done

# --- 4. auto-updater guard -------------------------------------------------
section "4. Auto-updater guard"

# Every account, the admin owner included. The updater maintains
# $HOME/.local/share/claude and has no other install location, so any account
# that runs it acquires a private copy and stops running the shared binary.
for user in "${ADMIN_OWNER}" "${AGENT_NAMES[@]}"; do
  value="$(as_user "${user}" 'echo "${DISABLE_AUTOUPDATER:-}"' 2>/dev/null)"
  if [[ "${value}" == "1" ]]; then
    ok "${user}: DISABLE_AUTOUPDATER=1"
  else
    bad "${user}: DISABLE_AUTOUPDATER='${value}', expected 1"
  fi
done

# The shared copy is the only binary that may exist anywhere on the machine.
#
# ~/.local/bin/claude is judged by what it points at, not by its presence. A
# symlink to the shared copy is a launcher: `claude doctor` otherwise reports
# that path as "missing or broken" and advises `claude install`, which would
# recreate the private install this setup removes. A symlink anywhere else --
# or a real file -- is an actual private install: a second binary that drifts
# from the fleet's version and re-enables its own auto-updates.
for user in "${ADMIN_OWNER}" "${AGENT_NAMES[@]}"; do
  launcher="${BASE_DIR}/${user}/.local/bin/claude"

  if sudo test -e "${BASE_DIR}/${user}/.local/share/claude"; then
    bad "${user} has a private install at ~/.local/share/claude"
  elif ! sudo test -e "${launcher}"; then
    ok "${user} has no private install"
  elif ! sudo test -L "${launcher}"; then
    bad "${user} has a real claude binary at ~/.local/bin/claude"
  elif [[ "$(sudo readlink "${launcher}")" == "${SHARED_BIN}" ]]; then
    ok "${user}'s ~/.local/bin/claude is a launcher to the shared copy"
  else
    bad "${user}'s ~/.local/bin/claude points at $(sudo readlink "${launcher}"), not the shared copy"
  fi
done

# --- 5. per-agent configuration --------------------------------------------
section "5. Per-agent configuration"

for agent in "${AGENT_NAMES[@]}"; do
  claude_dir="${BASE_DIR}/${agent}/.claude"
  printf "\n  [%s]\n" "${agent}"

  mode="$(stat_mode "${claude_dir}")"
  owner="$(stat_owner "${claude_dir}")"

  # 1775: group-write so Claude can write its own session state, sticky so the
  # agent cannot unlink the admin-owned rule links sitting in the same
  # directory.
  if [[ "${mode}" == "1775" ]]; then
    ok "~/.claude mode 1775 (group-writable, sticky)"
  else
    bad "~/.claude mode is ${mode}, expected 1775"
  fi

  if [[ "${owner}" == "${ADMIN_OWNER}:${DEVELOPERS_GROUP}" ]]; then
    ok "~/.claude owned by ${ADMIN_OWNER}:${DEVELOPERS_GROUP}"
  else
    bad "~/.claude owner is '${owner}'"
  fi

  for doc in "${RULES_ROOT_DOC}" "${HANDBOOK_DOCS[@]}"; do
    if ! sudo test -L "${claude_dir}/${doc}"; then
      bad "${doc} is not a symlink"
    elif ! as_user "${agent}" "test -r '${claude_dir}/${doc}'"; then
      bad "${doc} exists but the agent cannot read it"
    else
      ok "${doc} readable by the agent"
    fi
  done

  if as_user "${agent}" "test -r '${claude_dir}/settings.json'"; then
    if as_user "${agent}" "python3 -c 'import json,sys; json.load(open(sys.argv[1]))' '${claude_dir}/settings.json'"; then
      ok "settings.json readable and valid JSON"
    else
      bad "settings.json is not valid JSON"
    fi
  else
    bad "settings.json not readable by the agent"
  fi

  # Skills are pure config: no runtime writes land there, so unlike ~/.claude
  # itself it must not be agent-writable.
  skills_mode="$(stat_mode "${claude_dir}/skills")"
  if [[ "${skills_mode}" == "2750" ]]; then
    ok "skills/ mode 2750 (read-only to the agent)"
  else
    bad "skills/ mode is ${skills_mode}, expected 2750"
  fi
done

# --- 6. tamper resistance --------------------------------------------------
section "6. Tamper resistance"
note "canary link, not the real rules -- see header"

for agent in "${AGENT_NAMES[@]}"; do
  claude_dir="${BASE_DIR}/${agent}/.claude"
  canary="${claude_dir}/.verify-canary"

  sudo ln -sfn /dev/null "${canary}" 2>/dev/null

  if ! sudo test -L "${canary}"; then
    bad "${agent}: could not create canary, tamper check skipped"
    continue
  fi

  as_user "${agent}" "rm -f '${canary}'" >/dev/null 2>&1
  if sudo test -L "${canary}"; then
    ok "${agent}: cannot unlink an admin-owned link in ~/.claude"
  else
    bad "${agent}: UNLINKED an admin-owned link -- sticky bit not effective"
  fi

  as_user "${agent}" "mv '${canary}' '${canary}.moved'" >/dev/null 2>&1
  if sudo test -L "${canary}"; then
    ok "${agent}: cannot rename an admin-owned link in ~/.claude"
  else
    bad "${agent}: RENAMED an admin-owned link -- sticky bit not effective"
    sudo rm -f "${canary}.moved"
  fi

  sudo rm -f "${canary}"

  # The other half of the requirement: the protection must not have cost the
  # agent the ability to write its own session state.
  if as_user "${agent}" "mkdir -p '${claude_dir}/.verify-write' && rm -rf '${claude_dir}/.verify-write'"; then
    ok "${agent}: can still write its own runtime state"
  else
    bad "${agent}: cannot write runtime state into ~/.claude"
  fi
done

# --- 7. MCP ----------------------------------------------------------------
section "7. MCP provisioning"

verify_mcp_file() {
  local label="$1" path="$2" reader="$3"

  if ! sudo test -L "${path}"; then
    bad "${label}: .mcp.json is not a symlink"
    return
  fi
  if ! as_user "${reader}" "test -r '${path}'"; then
    bad "${label}: .mcp.json not readable by ${reader}"
    return
  fi
  if as_user "${reader}" "python3 -c 'import json,sys; d=json.load(open(sys.argv[1])); assert d[\"mcpServers\"]' '${path}'"; then
    ok "${label}: .mcp.json readable and defines servers"
  else
    bad "${label}: .mcp.json invalid or defines no servers"
  fi
}

verify_mcp_file "shared workspace" "${SHARED_WORKSPACE}/.mcp.json" "${AGENT_NAMES[0]}"

for agent in "${AGENT_NAMES[@]}"; do
  verify_mcp_file "${agent} workspace" "${BASE_DIR}/${agent}/workspace/.mcp.json" "${agent}"

  # Project-scoped servers need approval, which an unattended agent cannot
  # give. The approval has to come from user settings for it to apply in an
  # untrusted folder.
  if as_user "${agent}" "python3 -c 'import json,os,sys; d=json.load(open(os.path.expanduser(\"~/.claude/settings.json\"))); sys.exit(0 if d.get(\"enableAllProjectMcpServers\") else 1)'"; then
    ok "${agent}: enableAllProjectMcpServers set in user settings"
  else
    bad "${agent}: enableAllProjectMcpServers missing -- project MCP servers will sit unapproved"
  fi
done

# --- 8. credential isolation -----------------------------------------------
section "8. Credential isolation"

# Checked through `sudo -i -u`, the way the admin owner actually switches
# accounts, rather than through as_user -- the leak this guards against is a
# property of that transition.
for agent in "${AGENT_NAMES[@]}"; do
  leaked="$(sudo -n -i -u "${agent}" /usr/bin/env 2>/dev/null | grep -c '^SSH_AUTH_SOCK=')"
  if [[ "${leaked}" == "0" ]]; then
    ok "${agent}: does not inherit an ssh-agent socket"
  else
    bad "${agent}: inherits SSH_AUTH_SOCK -- can authenticate as the invoking user"
  fi
done

HELPER="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1])).get("apiKeyHelper",""))' \
  "${BASE_DIR}/${AGENT_NAMES[0]}/.claude/settings.json" 2>/dev/null)"
if [[ -n "${HELPER}" ]]; then
  ok "apiKeyHelper configured"
else
  bad "apiKeyHelper not set -- agents would fall back to /login and the Keychain"
fi

# These assertions name the key file and state what its modes should be, which
# does disclose it to anyone reading this script. That was weighed and accepted:
# the script sits in an admin-owned repo, the path is already in settings.json
# and the helper, and what the disclosure buys is a specific diagnosis. A use
# test in section 9 reports "cannot read its own API key"; these report which of
# mode or owner is wrong, and to what -- the difference between knowing
# something broke and knowing what to fix.
for agent in "${AGENT_NAMES[@]}"; do
  secret_dir="${BASE_DIR}/${agent}/anthropic-api-key"

  # 0500: the account reads and traverses, but cannot add, replace, or delete
  # without root. Directory write is what governs unlink on POSIX, so 0400 on
  # the key alone would still leave it replaceable by its own owner.
  mode="$(stat_mode "${secret_dir}")"
  if [[ "${mode}" == "0500" ]]; then
    ok "${agent}: key directory mode 0500 (no writes without root)"
  else
    bad "${agent}: key directory mode is ${mode}, expected 0500"
  fi

  if [[ -n "${HELPER}" ]] && as_user "${agent}" "test -x '${HELPER}'"; then
    ok "${agent}: can execute the key helper"
  else
    bad "${agent}: cannot execute the key helper"
  fi

  # Metadata only -- the file is never opened here. Section 9 does that.
  key_file="${secret_dir}/api_key.txt"

  if ! sudo test -e "${key_file}"; then
    warn "${agent}: no API key provisioned yet"
  else
    key_mode="$(stat_mode "${key_file}")"
    key_owner="$(stat_owner "${key_file}")"

    if [[ "${key_mode}" == "0400" ]]; then
      ok "${agent}: key file mode 0400 (owner read only)"
    else
      bad "${agent}: key file mode is ${key_mode}, expected 0400"
    fi

    # The failure this catches in practice: a key placed as root:admin, which
    # every mode check passes and the owning account still cannot read.
    if [[ "${key_owner}" == "${agent}:"* ]]; then
      ok "${agent}: key file owned by ${agent}"
    else
      bad "${agent}: key file owner is '${key_owner}', expected ${agent} -- the agent cannot read its own key"
    fi
  fi
done

# --- 9. use-based access checks --------------------------------------------
section "9. Use-based access checks"
note "performed as the agent -- real access attempts, not inferred from modes"

ADMIN_HOME="${BASE_DIR}/${ADMIN_OWNER}"

for agent in "${AGENT_NAMES[@]}"; do
  printf "\n  [%s]\n" "${agent}"

  # Positive: the shared workspace is the fleet's common ground, so an agent
  # that cannot write there is broken even though every mode looks right.
  probe="${SHARED_WORKSPACE}/.verify-write-${agent}"
  if as_user "${agent}" "touch '${probe}' && rm -f '${probe}'"; then
    ok "can create and remove a file in the shared workspace"
  else
    bad "cannot create a file in the shared workspace"
  fi
  # Belt and braces: if the touch succeeded and the rm did not, the probe would
  # otherwise be left behind in a directory the whole fleet shares.
  sudo rm -f "${probe}" 2>/dev/null

  # Positive: an actual read, since being readable by this account is the
  # file's entire purpose. `test -r` would only consult the access bit and
  # would still pass where an ACL, an extended attribute, or a sandbox blocks
  # the open itself. Output goes to /dev/null, so the key is never captured,
  # printed, or held in a shell variable -- here or in the negative check below.
  if as_user "${agent}" "cat '${BASE_DIR}/${agent}/anthropic-api-key/api_key.txt' >/dev/null 2>&1"; then
    ok "can read its own API key"
  else
    bad "cannot read its own API key"
  fi

  # Negative: per-agent credentials only bound the blast radius of a leak if
  # one agent genuinely cannot reach another's.
  #
  # Each target is confirmed to exist first, as root. Without that a negative
  # check passes for the wrong reason -- a key that was never provisioned, or a
  # mistyped path, is unreadable by everyone, and the check would report the
  # security property holding while testing nothing at all.
  leaked=""
  checked=0
  for other in "${AGENT_NAMES[@]}"; do
    [[ "${other}" != "${agent}" ]] || continue
    other_key="${BASE_DIR}/${other}/anthropic-api-key/api_key.txt"
    sudo test -e "${other_key}" || continue
    checked=$((checked + 1))
    if as_user "${agent}" "cat '${other_key}' >/dev/null 2>&1"; then
      leaked="${leaked:+${leaked} }${other}"
    fi
  done
  if [[ -n "${leaked}" ]]; then
    bad "can reach the API key of: ${leaked}"
  elif (( checked == 0 )); then
    warn "no other agent has a key provisioned -- isolation not exercised"
  else
    ok "cannot reach any other agent's API key (${checked} checked)"
  fi

  # Negative: the admin owner's home holds the credentials the whole setup is
  # built to keep away from agents.
  if ! sudo test -d "${ADMIN_HOME}"; then
    bad "${ADMIN_OWNER}'s home not found at ${ADMIN_HOME} -- this check would pass for the wrong reason"
  elif as_user "${agent}" "ls '${ADMIN_HOME}' >/dev/null 2>&1"; then
    bad "can list ${ADMIN_OWNER}'s home directory"
  else
    ok "cannot reach ${ADMIN_OWNER}'s home directory"
  fi
done

# --- 10. authentication ----------------------------------------------------
section "10. Authentication"
note "credential source and liveness, per agent -- no key material leaves the agent"

# `claude auth status` reports which credential Claude Code actually selected,
# which is the one thing every check above stops short of: sections 8 and 9
# prove the key file is present, correctly owned, and readable by its account,
# but not that Claude Code found it and chose it. This closes that gap without
# an API call.
#
# Its JSON carries no secret -- only loggedIn, authMethod, apiProvider and
# apiKeySource -- so it is safe to parse here rather than inside the agent's
# shell.
#
# What it does NOT prove: that the key is still live at Anthropic. It reports
# the credential Claude Code holds, not one the server has accepted. A revoked
# key still reports loggedIn. Only a real request settles that.
for agent in "${AGENT_NAMES[@]}"; do
  status_json="$(as_user "${agent}" 'claude auth status' 2>/dev/null || true)"

  if [[ -z "${status_json}" ]]; then
    bad "${agent}: claude auth status returned nothing"
    continue
  fi

  parsed="$(printf '%s' "${status_json}" | python3 -c '
import json, sys
try:
    d = json.load(sys.stdin)
except Exception:
    print("parse_error parse_error")
    raise SystemExit(0)
print(d.get("loggedIn"), d.get("apiKeySource"))
' 2>/dev/null)"

  logged_in="${parsed%% *}"
  key_source="${parsed##* }"

  if [[ "${logged_in}" == "True" ]]; then
    ok "${agent}: authenticated"
  else
    bad "${agent}: not authenticated (loggedIn=${logged_in:-unknown})"
  fi

  # The source matters as much as the outcome. An agent authenticated by a
  # stray ANTHROPIC_API_KEY in its environment, or by a keychain login someone
  # performed by hand, would report loggedIn just the same -- while running on
  # a credential this setup does not manage and cannot revoke per agent.
  if [[ "${key_source}" == "apiKeyHelper" ]]; then
    ok "${agent}: credential comes from the managed apiKeyHelper"
  else
    bad "${agent}: credential source is '${key_source}', expected apiKeyHelper"
  fi

  # Liveness: the one thing `auth status` cannot tell you. It reports the
  # credential Claude Code holds; this asks Anthropic whether that credential is
  # still accepted. A revoked or mistyped key reports loggedIn identically and
  # fails only on the agent's first real request -- typically unattended, hours
  # later, as an opaque 401.
  #
  # GET /v1/models is the cheapest way to ask: it authenticates the key and
  # generates nothing, so no tokens are billed.
  #
  # The whole exchange runs inside the agent's own shell -- the key is read by
  # the helper there and spent on the request there. Only the HTTP status code
  # crosses back, so the verifier still never handles key material.
  http_code="$(as_user "${agent}" "key=\$('${HELPER}' 2>/dev/null) || exit 1
    curl -sS --max-time 15 -o /dev/null -w '%{http_code}' \
      -H \"x-api-key: \${key}\" \
      -H 'anthropic-version: 2023-06-01' \
      https://api.anthropic.com/v1/models 2>/dev/null" 2>/dev/null || true)"

  case "${http_code}" in
    200)
      ok "${agent}: key accepted by the API (live)"
      ;;
    401|403)
      bad "${agent}: key rejected by the API (HTTP ${http_code}) -- revoked, mistyped, or wrong organization"
      ;;
    429)
      # The key authenticated; the org is simply at its limit.
      ok "${agent}: key accepted (HTTP 429 -- rate limited, but authenticated)"
      ;;
    000|"")
      # No network is not a misconfiguration, and a CI gate that fails on it
      # would block on something this machine cannot fix.
      warn "${agent}: could not reach the API -- liveness not verified (offline?)"
      ;;
    *)
      bad "${agent}: unexpected API response (HTTP ${http_code})"
      ;;
  esac
done

# --- summary ---------------------------------------------------------------
printf "\n${C_HEAD}Summary${C_OFF}\n"
printf "  passed:   %d\n" "${PASS}"
printf "  failed:   %d\n" "${FAIL}"
printf "  warnings: %d\n" "${WARN}"

# Warnings never affect the exit status: outstanding provisioning is not a
# misconfiguration, and a CI gate that fails on it would block on work the
# machine cannot do for itself.
if (( WARN > 0 && FAIL == 0 )); then
  printf "\n${C_WARN}%d warning(s) -- provisioning incomplete, nothing misconfigured.${C_OFF}\n" "${WARN}"
fi

if (( FAIL > 0 )); then
  printf "\n${C_BAD}%d check(s) failed.${C_OFF}\n" "${FAIL}"
  exit 1
fi

printf "\n${C_OK}All checks passed.${C_OFF}\n"
