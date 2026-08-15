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
# Read-only with one exception: the tamper checks in section 6 create a
# root-owned canary symlink and try to remove it as the agent. The real rule
# links are never touched -- attempting to delete those would destroy the
# configuration precisely when the protection is broken, which is the one
# moment a verifier must not make things worse. The canary sits in the same
# directory with the same ownership, so the unlink rules that apply to it are
# the rules that apply to them.

if [[ -t 1 ]]; then
  C_OK=$'\033[32m'; C_BAD=$'\033[31m'; C_HEAD=$'\033[1m'; C_OFF=$'\033[0m'
else
  C_OK=""; C_BAD=""; C_HEAD=""; C_OFF=""
fi

PASS=0
FAIL=0

ok()   { printf "  ${C_OK}PASS${C_OFF}  %s\n" "$*"; PASS=$((PASS + 1)); }
bad()  { printf "  ${C_BAD}FAIL${C_OFF}  %s\n" "$*"; FAIL=$((FAIL + 1)); }
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

  version="$(as_user "${user}" 'claude --version' 2>/dev/null | head -1)"
  if [[ -z "${REF_VERSION}" ]]; then
    REF_VERSION="${version}"
    note "reference version: ${REF_VERSION}"
  elif [[ "${version}" != "${REF_VERSION}" ]]; then
    bad "${user}: version '${version}' differs from '${REF_VERSION}'"
  fi
done

# --- 4. auto-updater guard -------------------------------------------------
section "4. Auto-updater guard"

for agent in "${AGENT_NAMES[@]}"; do
  value="$(as_user "${agent}" 'echo "${DISABLE_AUTOUPDATER:-}"' 2>/dev/null)"
  if [[ "${value}" == "1" ]]; then
    ok "${agent}: DISABLE_AUTOUPDATER=1"
  else
    bad "${agent}: DISABLE_AUTOUPDATER='${value}', expected 1"
  fi
done

admin_value="$(as_user "${ADMIN_OWNER}" 'echo "${DISABLE_AUTOUPDATER:-}"' 2>/dev/null)"
if [[ -z "${admin_value}" ]]; then
  ok "${ADMIN_OWNER}: auto-updater left enabled"
else
  bad "${ADMIN_OWNER}: DISABLE_AUTOUPDATER='${admin_value}', expected unset"
fi

# The shared copy is the only one meant to exist. A private install in the
# admin owner's home means the updater has recreated one, and the fleet will
# drift from whatever that copy becomes.
if sudo test -e "${BASE_DIR}/${ADMIN_OWNER}/.local/share/claude"; then
  bad "${ADMIN_OWNER} has a private install at ~/.local/share/claude"
else
  ok "${ADMIN_OWNER} has no private install"
fi

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

# --- summary ---------------------------------------------------------------
printf "\n${C_HEAD}Summary${C_OFF}\n"
printf "  passed: %d\n" "${PASS}"
printf "  failed: %d\n" "${FAIL}"

if (( FAIL > 0 )); then
  printf "\n${C_BAD}%d check(s) failed.${C_OFF}\n" "${FAIL}"
  exit 1
fi

printf "\n${C_OK}All checks passed.${C_OFF}\n"
