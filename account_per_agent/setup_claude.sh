#!/usr/bin/env bash
set -euo pipefail

# Provisions ~/.claude for every agent account, the Claude Code counterpart to
# what setup.sh does for ~/.gemini. The two are deliberately separate scripts:
# setup.sh is in service and Gemini-specific, and a fault here must not be able
# to take that fleet down.
#
# The binary itself is not installed here -- install_claude_shared.sh publishes
# one admin-owned copy that every account runs. This script only provisions
# configuration.
#
# Every check guards a privileged chown/chmod, and no caller recovers from a
# failed check, so a failed assertion always ends the run.
fail() {
  echo "$*" >&2
  exit 1
}

OS_NAME="$(uname -s)"
case "${OS_NAME}" in
  Darwin)
    DEFAULT_HOME_BASE="/Users"
    DEFAULT_ADMINS_GROUP="admin"
    ;;
  Linux)
    DEFAULT_HOME_BASE="/home"
    DEFAULT_ADMINS_GROUP="sudo"
    ;;
  *)
    fail "Unsupported platform: ${OS_NAME} (supported: Darwin, Linux)"
    ;;
esac

BASE_DIR="${AGENT_HOME_BASE:-${DEFAULT_HOME_BASE}}"

# -P resolves symlinks in the invocation path, so the config symlinks this
# script plants are physical paths every account can follow. See setup.sh.
SCRIPT_DIR="$(cd -P "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
HANDBOOK_DIR="$(dirname "${SCRIPT_DIR}")"
CLAUDE_CONFIG_DIR="${SCRIPT_DIR}/config/claude"
CLAUDE_SKILLS_DIR="${CLAUDE_CONFIG_DIR}/skills"
CLAUDE_MCP_FILE="${CLAUDE_CONFIG_DIR}/mcp.json"

# MCP is provisioned at project scope -- a .mcp.json at the root of each
# workspace -- rather than through /Library/Application Support/ClaudeCode/
# managed-mcp.json.
#
# managed-mcp.json looks like the natural admin mechanism, but it takes
# exclusive control: Claude Code then loads only the servers it names, ignoring
# plugin-provided servers, and any session started with --mcp-config exits at
# startup rather than dropping the extra servers. It is also machine-wide, so
# that would apply to the admin owner's own IDE-driven sessions.
#
# Project scope reaches exactly the two places agents work and restricts
# nothing else. It normally needs a workspace trust dialog, which would block
# an unattended agent -- but an approval in the user's own settings.json
# applies even in an untrusted folder, and settings.json here is the
# admin-owned symlink. That is what enableAllProjectMcpServers is doing in it.
SHARED_WORKSPACE="${SHARED_WORKSPACE:-/Users/Shared/workspace}"

# The same handbook documents setup.sh links into ~/.gemini. They contain no
# CLI-specific paths, so both fleets read the identical files.
HANDBOOK_DOCS=(
  "RULES.md"
  "PHILOSOPHY.md"
  "WORKFLOW.md"
  "GIT_HUB.md"
)

# Claude Code loads ~/.claude/CLAUDE.md automatically, exactly as Gemini loads
# ~/.gemini/GEMINI.md. Same source document, different link name -- which is
# why it cannot live in HANDBOOK_DOCS above.
AGENTS_DOC_SOURCE="use-rules-AGENTS.md"
AGENTS_DOC_LINK_NAME="CLAUDE.md"

DEVELOPERS_GROUP="${DEVELOPERS_GROUP:-developers}"
ADMINS_GROUP="${ADMINS_GROUP:-${DEFAULT_ADMINS_GROUP}}"

list_all_users() {
  case "${OS_NAME}" in
    Darwin) dscl . -list /Users 2>/dev/null ;;
    Linux)  getent passwd | cut -d: -f1 ;;
  esac
}

user_in_group() {
  id -Gn "$1" 2>/dev/null | tr ' ' '\n' | grep -qx "$2"
}

# Identical derivation to setup.sh, so both scripts always agree on who is an
# agent and who is the admin owner:
#   AGENTS       in DEVELOPERS_GROUP, not in ADMINS_GROUP
#   ADMIN_OWNER  in both
resolve_identities() {
  local user
  local discovered_agents=""
  local discovered_admins=""

  for user in $(list_all_users); do
    user_in_group "${user}" "${DEVELOPERS_GROUP}" || continue

    if user_in_group "${user}" "${ADMINS_GROUP}"; then
      discovered_admins="${discovered_admins:+${discovered_admins} }${user}"
    else
      discovered_agents="${discovered_agents:+${discovered_agents} }${user}"
    fi
  done

  if [[ -z "${ADMIN_OWNER:-}" ]]; then
    local admin_count=0
    for user in ${discovered_admins}; do
      admin_count=$((admin_count + 1))
    done

    (( admin_count != 0 )) || fail "No account is in both ${DEVELOPERS_GROUP} and ${ADMINS_GROUP}; set ADMIN_OWNER explicitly"
    (( admin_count == 1 )) || fail "Several accounts are in both ${DEVELOPERS_GROUP} and ${ADMINS_GROUP} (${discovered_admins}); set ADMIN_OWNER explicitly"

    ADMIN_OWNER="${discovered_admins}"
    echo "Discovered ADMIN_OWNER: ${ADMIN_OWNER} (in ${DEVELOPERS_GROUP} + ${ADMINS_GROUP})"
  fi

  if [[ -z "${AGENTS:-}" ]]; then
    AGENTS="${discovered_agents}"
    echo "Discovered AGENTS: ${AGENTS:-<none>} (in ${DEVELOPERS_GROUP}, not in ${ADMINS_GROUP})"
  fi

  [[ -n "${AGENTS}" ]] || fail "No ${DEVELOPERS_GROUP} members outside ${ADMINS_GROUP} found; nothing to do"
}

assert_user_exists() {
  local name="$1"

  [[ "${name}" =~ ^[a-z_][a-z0-9_-]*$ ]] || fail "Invalid account name: ${name}"
  id -u "${name}" >/dev/null 2>&1 || fail "User does not exist: ${name}"
}

assert_group_exists() {
  local name="$1"

  case "${OS_NAME}" in
    Darwin) dscl . -read "/Groups/${name}" >/dev/null 2>&1 ;;
    Linux)  getent group "${name}" >/dev/null 2>&1 ;;
  esac || fail "Group does not exist: ${name}"
}

assert_identities() {
  [[ ${#AGENT_NAMES[@]} -gt 0 ]] || fail "AGENTS must name at least one agent account"

  assert_user_exists "${ADMIN_OWNER}"
  user_in_group "${ADMIN_OWNER}" "${DEVELOPERS_GROUP}" || fail "${ADMIN_OWNER} must belong to ${DEVELOPERS_GROUP}"
  user_in_group "${ADMIN_OWNER}" "${ADMINS_GROUP}" || fail "${ADMIN_OWNER} must belong to ${ADMINS_GROUP}"

  local agent
  for agent in "${AGENT_NAMES[@]}"; do
    assert_user_exists "${agent}"
    user_in_group "${agent}" "${DEVELOPERS_GROUP}" || fail "Agent ${agent} must belong to ${DEVELOPERS_GROUP}"
    # Agents must not be able to reach each other's secrets through the admin group.
    ! user_in_group "${agent}" "${ADMINS_GROUP}" || fail "Agent ${agent} must not belong to ${ADMINS_GROUP}"
  done
}

assert_not_symlink() {
  local description="$1"
  local target="$2"

  [[ ! -L "${target}" ]] || fail "Refusing to apply ${description} permissions to symlink: ${target}"
}

# ~/.claude differs from ~/.gemini in one way that matters: Claude Code writes
# a lot of its own state into it -- sessions/, projects/, history.jsonl,
# shell-snapshots/, cache/ -- so the directory cannot be made read-only to the
# agent the way a pure config tree could be.
#
# Group write lets the agent create that state. The sticky bit is what keeps
# the arrangement safe: on POSIX it is write permission on the *containing
# directory* that governs unlink and rename, not ownership of the entry, so
# without +t an agent could delete the CLAUDE.md symlink and drop in its own
# file -- detaching itself from the rules it is meant to run under, while never
# having write access to the handbook. With +t, only the entry's owner (root,
# for the links) can unlink or rename it.
apply_agent_claude_dir_permission() {
  local description="$1"
  local target="$2"

  assert_not_symlink "${description}" "${target}"

  sudo chown "${ADMIN_OWNER}:${DEVELOPERS_GROUP}" "${target}"
  sudo chmod 1775 "${target}"
}

# Skills are pure admin-owned config: no runtime writes land here, so unlike
# ~/.claude itself this stays read-only to agents.
#
# Only directories are touched. The leaves are symlinks, and chmod/chown follow
# a symlink to its target -- a recursive pass would reach out of the agent's
# tree and rewrite the admin repo originals.
apply_agent_skills_permission() {
  local description="$1"
  local target="$2"

  assert_not_symlink "${description}" "${target}"

  sudo find "${target}" -type d -exec chown "${ADMIN_OWNER}:${DEVELOPERS_GROUP}" {} +
  sudo find "${target}" -type d -exec chmod 2750 {} +
}

apply_admin_config_permission() {
  local description="$1"
  local target="$2"

  assert_not_symlink "${description}" "${target}"

  sudo chown -RhP "${ADMIN_OWNER}:${DEVELOPERS_GROUP}" "${target}"
  sudo find "${target}" -type d -exec chmod 2750 {} +
  sudo find "${target}" -type f -exec chmod 0640 {} +
}

# An ACL on the directory inherits to files created later, which a mode does
# not. The handbook is a git working tree, so checkout/pull replaces a
# document's inode and its mode reverts to the writer's umask -- silently
# leaving every agent's symlink pointing at a file it can no longer open.
# Re-adding an existing ACE is a no-op, so this is safe on every run.
grant_inherited_group_read() {
  local dir="$1"
  shift

  assert_not_symlink "inherited-read-acl" "${dir}"

  local file
  case "${OS_NAME}" in
    Darwin)
      sudo chmod +a "group:${DEVELOPERS_GROUP} allow list,search,readattr,readextattr,readsecurity,file_inherit" "${dir}"
      for file in "$@"; do
        sudo chmod +a "group:${DEVELOPERS_GROUP} allow read,readattr,readextattr,readsecurity" "${file}"
      done
      ;;
    Linux)
      sudo setfacl -m "d:g:${DEVELOPERS_GROUP}:r-x" -m "g:${DEVELOPERS_GROUP}:r-x" "${dir}"
      for file in "$@"; do
        sudo setfacl -m "g:${DEVELOPERS_GROUP}:r--" "${file}"
      done
      ;;
  esac
}

# Replace a config symlink without ever recursively deleting a real directory.
link_agent_config() {
  local link_path="$1"
  local target="$2"

  if [[ -e "${link_path}" && ! -L "${link_path}" ]]; then
    fail "Refusing to replace non-symlink config path: ${link_path}"
  fi

  sudo rm -f "${link_path}"
  sudo ln -sfn "${target}" "${link_path}"
}

# Real directories, symlinked leaves. The CLI walks the skills tree with a
# readdir scan that filters on isFile(), which does not report a symlinked
# directory -- so the directories have to be real entries. The files it opens
# by path, so those can be links, and symbolic rather than hard: a symlink
# resolves by path and so survives git checkout/pull replacing the source
# inode, which a hard link would not.
mirror_skills_tree() {
  local src="$1"
  local dest="$2"
  local rel

  # mkdir -p on a symlink to a directory succeeds silently, which would write
  # every link below into whatever it points at -- the admin repo itself.
  [[ ! -L "${dest}" ]] || sudo rm -f "${dest}"

  case "${dest}" in
    "${BASE_DIR}"/*/.claude/skills) : ;;
    *) fail "Refusing to rebuild unexpected skills path: ${dest}" ;;
  esac

  sudo mkdir -p "${dest}"

  # Every leaf here is a symlink this script owns, so clearing them all and
  # recreating them leaves nothing behind from a skill since deleted upstream.
  # Not an rm -rf: a directory removed upstream lingers as an empty directory
  # until someone deletes it by hand, which is the cheaper failure.
  sudo find "${dest}" -type l -delete

  # Enumerated up front so a failure aborts the run. A `while read` fed by a
  # process substitution cannot do that: set -e does not see a failure inside
  # <(...), so an unreadable source tree would provision an empty skills
  # directory and report success. pipefail carries a find failure through sed.
  local dir_list file_list
  dir_list="$(cd "${src}" && find -L . -mindepth 1 -type d | sed 's|^\./||')" \
    || fail "Cannot enumerate skill directories under ${src}"
  file_list="$(cd "${src}" && find -L . -mindepth 1 -type f | sed 's|^\./||')" \
    || fail "Cannot enumerate skill files under ${src}"

  # Directories first -- a file must never precede its parent. -L classifies by
  # what a link points at, so a symlink upstream is recreated as a link to the
  # same file rather than a link to a link.
  local rel
  while read -r rel; do
    [[ -n "${rel}" ]] || continue
    sudo mkdir -p "${dest}/${rel}"
  done <<<"${dir_list}"

  while read -r rel; do
    [[ -n "${rel}" ]] || continue
    sudo ln -s "${src}/${rel}" "${dest}/${rel}"
  done <<<"${file_list}"
}

echo "=== Provisioning Claude Code for agents ==="

assert_group_exists "${DEVELOPERS_GROUP}"
assert_group_exists "${ADMINS_GROUP}"

resolve_identities
read -r -a AGENT_NAMES <<<"${AGENTS}"
assert_identities

[[ -d "${CLAUDE_CONFIG_DIR}" ]] || fail "Claude config directory not found: ${CLAUDE_CONFIG_DIR}"
[[ -f "${CLAUDE_CONFIG_DIR}/settings.json" ]] || fail "Missing ${CLAUDE_CONFIG_DIR}/settings.json"
[[ -f "${CLAUDE_MCP_FILE}" ]] || fail "Missing ${CLAUDE_MCP_FILE}"
sudo mkdir -p "${CLAUDE_SKILLS_DIR}"

apply_admin_config_permission "claude-config" "${CLAUDE_CONFIG_DIR}"

# Link targets must exist and be group-readable before any agent gets a link to
# them, or the link resolves to a file the agent cannot open.
LINKED_DOC_PATHS=()
for DOC in "${HANDBOOK_DOCS[@]}" "${AGENTS_DOC_SOURCE}"; do
  DOC_PATH="${HANDBOOK_DIR}/${DOC}"
  [[ -f "${DOC_PATH}" ]] || fail "Handbook document not found: ${DOC_PATH}"
  LINKED_DOC_PATHS+=("${DOC_PATH}")
done

grant_inherited_group_read "${HANDBOOK_DIR}" "${LINKED_DOC_PATHS[@]}"
grant_inherited_group_read "${CLAUDE_CONFIG_DIR}"

# The shared workspace is one directory for the whole fleet, so its .mcp.json
# is linked once rather than per agent.
if [[ -d "${SHARED_WORKSPACE}" ]]; then
  link_agent_config "${SHARED_WORKSPACE}/.mcp.json" "${CLAUDE_MCP_FILE}"
  echo "Linked ${SHARED_WORKSPACE}/.mcp.json"
else
  echo "Shared workspace not found, skipping its .mcp.json: ${SHARED_WORKSPACE}" >&2
fi

for AGENT in "${AGENT_NAMES[@]}"; do
  AGENT_DIR="${BASE_DIR}/${AGENT}"
  CLAUDE_DIR="${AGENT_DIR}/.claude"
  AGENT_SKILLS_DIR="${CLAUDE_DIR}/skills"
  AGENT_WORKSPACE="${AGENT_DIR}/workspace"

  echo "[+] Processing: ${AGENT}"

  [[ -d "${AGENT_DIR}" ]] || fail "Home directory does not exist for ${AGENT}: ${AGENT_DIR}"

  # Created as the agent so a first run on a fresh account does not leave a
  # root-owned directory the agent cannot write its session state into.
  sudo -u "${AGENT}" mkdir -p "${CLAUDE_DIR}"

  # The rules. Same source documents as ~/.gemini, so both fleets are governed
  # by one set of files.
  for DOC in "${HANDBOOK_DOCS[@]}"; do
    link_agent_config "${CLAUDE_DIR}/${DOC}" "${HANDBOOK_DIR}/${DOC}"
  done
  link_agent_config "${CLAUDE_DIR}/${AGENTS_DOC_LINK_NAME}" "${HANDBOOK_DIR}/${AGENTS_DOC_SOURCE}"

  link_agent_config "${CLAUDE_DIR}/settings.json" "${CLAUDE_CONFIG_DIR}/settings.json"

  # setup.sh owns the private workspace; created here too so this script also
  # works on an account setup.sh has not reached yet.
  sudo -u "${AGENT}" mkdir -p "${AGENT_WORKSPACE}"
  link_agent_config "${AGENT_WORKSPACE}/.mcp.json" "${CLAUDE_MCP_FILE}"

  mirror_skills_tree "${CLAUDE_SKILLS_DIR}" "${AGENT_SKILLS_DIR}"

  # Outermost first, so the tighter inner modes are written last and the
  # recursive pass above them cannot undo the modes below.
  apply_agent_claude_dir_permission "${AGENT}-claude" "${CLAUDE_DIR}"
  apply_agent_skills_permission "${AGENT}-claude-skills" "${AGENT_SKILLS_DIR}"

  echo "[✓] ${AGENT} provisioned."
done

echo "=== All agents processed ==="
echo
echo "Each agent must still authenticate once. On macOS the credential is"
echo "stored in that account's login Keychain, not under ~/.claude, so it is"
echo "isolated per account and cannot be provisioned from here."
