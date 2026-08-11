#!/usr/bin/env bash
set -euo pipefail

# Every check in this script guards a privileged chown/chmod, and no caller
# recovers from a failed check, so a failed assertion always ends the run.
fail() {
  echo "$*" >&2
  exit 1
}

# Supported platforms: macOS and Debian.
OS_NAME="$(uname -s)"
case "${OS_NAME}" in
  Darwin)
    DEFAULT_HOME_BASE="/Users"
    ROOT_GROUP="wheel"
    DEFAULT_ADMINS_GROUP="admin"
    ;;
  Linux)
    DEFAULT_HOME_BASE="/home"
    ROOT_GROUP="root"
    DEFAULT_ADMINS_GROUP="sudo"
    ;;
  *)
    fail "Unsupported platform: ${OS_NAME} (supported: Darwin, Linux)"
    ;;
esac

# Overridable so the script can run against non-default layouts.
BASE_DIR="${AGENT_HOME_BASE:-${DEFAULT_HOME_BASE}}"

# -P resolves symlinks in the invocation path. Plain `pwd` reports the logical
# path, so running this through e.g. ~/shared -> /Users/Shared would bake a
# per-user path into every agent's config symlinks, which other accounts cannot
# follow. Agents need the physical, universally reachable path.
SCRIPT_DIR="$(cd -P "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
HANDBOOK_DIR="$(dirname "${SCRIPT_DIR}")"
ADMIN_REPO_CONFIG_DIR="${SCRIPT_DIR}/config"
ADMIN_REPO_SCRIPTS_DIR="${ADMIN_REPO_CONFIG_DIR}/scripts"

# Handbook documents every agent reads. Linked individually into ~/.gemini so an
# agent sees them at a stable path without gaining the whole handbook tree.
HANDBOOK_DOCS=(
  "RULES.md"
  "PHILOSOPHY.md"
  "WORKFLOW.md"
  "GIT_HUB.md"
)

DEVELOPERS_GROUP="${DEVELOPERS_GROUP:-developers}"
# Privileged group guarding agent homes and secrets: the platform's admin group
# ("admin" on macOS, "sudo" on Debian). Members read agent secrets without sudo,
# so agent accounts must not belong to it.
ADMINS_GROUP="${ADMINS_GROUP:-${DEFAULT_ADMINS_GROUP}}"

# Every local account name, so membership can be resolved with `id`, which sees
# primary groups as well as the explicit member lists the directory stores.
list_all_users() {
  case "${OS_NAME}" in
    Darwin) dscl . -list /Users 2>/dev/null ;;
    Linux)  getent passwd | cut -d: -f1 ;;
  esac
}

user_in_group() {
  local name="$1"
  local group="$2"

  id -Gn "${name}" 2>/dev/null | tr ' ' '\n' | grep -qx "${group}"
}

# Identities are derived from group membership and can be overridden from
# outside. Membership in the admin group is what separates the two roles:
#   AGENTS       members of DEVELOPERS_GROUP that are NOT in ADMINS_GROUP
#   ADMIN_OWNER  member of both DEVELOPERS_GROUP and ADMINS_GROUP
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

    if (( admin_count == 0 )); then
      fail "No account is in both ${DEVELOPERS_GROUP} and ${ADMINS_GROUP}; set ADMIN_OWNER explicitly"
    fi

    # Ambiguous ownership is a configuration question, not something to guess at.
    if (( admin_count > 1 )); then
      fail "Several accounts are in both ${DEVELOPERS_GROUP} and ${ADMINS_GROUP} (${discovered_admins}); set ADMIN_OWNER explicitly"
    fi

    ADMIN_OWNER="${discovered_admins}"
    echo "Discovered ADMIN_OWNER: ${ADMIN_OWNER} (in ${DEVELOPERS_GROUP} + ${ADMINS_GROUP})"
  fi

  if [[ -z "${AGENTS:-}" ]]; then
    AGENTS="${discovered_agents}"
    echo "Discovered AGENTS: ${AGENTS:-<none>} (in ${DEVELOPERS_GROUP}, not in ${ADMINS_GROUP})"
  fi

  if [[ -z "${AGENTS}" ]]; then
    fail "No ${DEVELOPERS_GROUP} members outside ${ADMINS_GROUP} found; nothing to do"
  fi
}

# Names arrive from AGENTS/ADMIN_OWNER or group discovery and end up in sudo,
# chown, and find arguments, so require a plain account name before resolving it.
# The pattern also rejects bare numbers, which `id -u` would resolve as a uid.
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
  if [[ ${#AGENT_NAMES[@]} -eq 0 ]]; then
    fail "AGENTS must name at least one agent account"
  fi

  assert_user_exists "${ADMIN_OWNER}"

  local agent
  for agent in "${AGENT_NAMES[@]}"; do
    assert_user_exists "${agent}"
  done

  # The admin owner writes the shared config and reads agent secrets, so it must
  # hold both roles.
  if ! user_in_group "${ADMIN_OWNER}" "${DEVELOPERS_GROUP}"; then
    fail "${ADMIN_OWNER} must belong to ${DEVELOPERS_GROUP}"
  fi

  if ! user_in_group "${ADMIN_OWNER}" "${ADMINS_GROUP}"; then
    fail "${ADMIN_OWNER} must belong to ${ADMINS_GROUP}"
  fi

  for agent in "${AGENT_NAMES[@]}"; do
    # Agents share the workspace tree through the developers group...
    if ! user_in_group "${agent}" "${DEVELOPERS_GROUP}"; then
      fail "Agent ${agent} must belong to ${DEVELOPERS_GROUP}"
    fi

    # ...but must not reach each other's secrets through the admin group.
    if user_in_group "${agent}" "${ADMINS_GROUP}"; then
      fail "Agent ${agent} must not belong to ${ADMINS_GROUP}"
    fi
  done
}

assert_not_symlink() {
  local description="$1"
  local target="$2"

  if [[ -L "${target}" ]]; then
    fail "Refusing to apply ${description} permissions to symlink: ${target}"
  fi
}

assert_safe_path_name() {
  local name="$1"

  if [[ ! "${name}" =~ ^[A-Za-z0-9._-]+$ ]]; then
    fail "Unsafe /etc/paths.d file name: ${name}"
  fi
}

apply_agent_home_permission() {
  local description="$1"
  local target="$2"

  assert_not_symlink "${description}" "${target}"

  sudo chown "${AGENT}:${ADMINS_GROUP}" "${target}"
  sudo chmod 2775 "${target}"
}

# Recursive chown that never follows symlinks. GNU chown dereferences by default,
# so a symlink planted inside an agent-writable tree could otherwise retarget the
# ownership change at an arbitrary file. -h acts on the link, -P never traverses.
chown_tree() {
  local owner="$1"
  local target="$2"

  sudo chown -RhP "${owner}" "${target}"
}

apply_workspace_permissions() {
  local description="$1"
  local target="$2"

  assert_not_symlink "${description}" "${target}"

  chown_tree "${AGENT}:${DEVELOPERS_GROUP}" "${target}"
  sudo find "${target}" -type d -exec chmod 2775 {} +
  # Preserve the executable bit: checked-out scripts, venv/bin, node_modules/.bin
  # must keep working across re-runs. Bucketing by the current owner-exec bit
  # keeps this idempotent and still clears setuid/setgid on files.
  sudo find "${target}" -type f -perm -u+x -exec chmod 0775 {} +
  sudo find "${target}" -type f ! -perm -u+x -exec chmod 0664 {} +
}

apply_secret_permission() {
  local description="$1"
  local target="$2"

  assert_not_symlink "${description}" "${target}"

  chown_tree "${AGENT}:${ADMINS_GROUP}" "${target}"
  sudo find "${target}" -type d -exec chmod 2550 {} +
  sudo find "${target}" -type f -exec chmod 0440 {} +
}

apply_agent_secret_permission() {
  local description="$1"
  local target="$2"

  assert_not_symlink "${description}" "${target}"

  chown_tree "${AGENT}:${ADMINS_GROUP}" "${target}"
  sudo find "${target}" -type d -exec chmod 2750 {} +
  sudo find "${target}" -type f -exec chmod 0640 {} +
}

apply_admin_workspace_permission() {
  local description="$1"
  local target="$2"

  assert_not_symlink "${description}" "${target}"

  chown_tree "${ADMIN_OWNER}:${DEVELOPERS_GROUP}" "${target}"
  sudo find "${target}" -type d -exec chmod 2750 {} +
  sudo find "${target}" -type f -exec chmod 0640 {} +
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

register_on_path() {
  local description="$1"
  local target="$2"
  local path_file

  if [[ -d "/etc/paths.d" ]]; then
    # macOS path_helper
    path_file="/etc/paths.d/${description}"
    printf '%s\n' "${target}" | sudo tee "${path_file}" >/dev/null
  elif [[ -d "/etc/profile.d" ]]; then
    path_file="/etc/profile.d/${description}.sh"
    printf 'export PATH="$PATH:%s"\n' "${target}" | sudo tee "${path_file}" >/dev/null
  else
    echo "No supported PATH drop-in directory found; skipping PATH registration for ${target}" >&2
    return 0
  fi

  sudo chown "root:${ROOT_GROUP}" "${path_file}"
  sudo chmod 0644 "${path_file}"
}

apply_scripts_permission() {
  local description="$1"
  local target="$2"

  assert_safe_path_name "${description}"
  assert_not_symlink "${description}" "${target}"

  if [[ ! -d "${target}" ]]; then
    fail "Script permission target must be a directory: ${target}"
  fi

  chown_tree "${ADMIN_OWNER}:${DEVELOPERS_GROUP}" "${target}"
  sudo find "${target}" -type d -exec chmod 2750 {} +
  sudo find "${target}" -type f -exec chmod 0750 {} +

  register_on_path "${description}" "${target}"
}

echo "=== Initializing Agents ==="

assert_group_exists "${DEVELOPERS_GROUP}"
assert_group_exists "${ADMINS_GROUP}"

resolve_identities
read -r -a AGENT_NAMES <<<"${AGENTS}"

assert_identities

apply_admin_workspace_permission "agent-config" "${ADMIN_REPO_CONFIG_DIR}"
apply_scripts_permission "agent-scripts" "${ADMIN_REPO_SCRIPTS_DIR}"

# Link targets must exist before any agent gets a link to them, and they must be
# group-readable or the link resolves to a file the agent cannot open.
for DOC in "${HANDBOOK_DOCS[@]}"; do
  DOC_PATH="${HANDBOOK_DIR}/${DOC}"
  [[ -f "${DOC_PATH}" ]] || fail "Handbook document not found: ${DOC_PATH}"
  apply_admin_workspace_permission "handbook-${DOC}" "${DOC_PATH}"
done

for AGENT in "${AGENT_NAMES[@]}"; do
  AGENT_DIR="${BASE_DIR}/${AGENT}"
  WORKSPACE_DIR="${AGENT_DIR}/workspace"
  SECRETS_DIR="${AGENT_DIR}/secrets"
  CREATED_BY_AGENT_SECRETS_DIR="${SECRETS_DIR}/created_by_agent"
  GEMINI_DIR="${AGENT_DIR}/.gemini"
  GEMINI_CONFIG_LINK="${GEMINI_DIR}/config"

  echo "[+] Processing: ${AGENT}"

  # Create the whole layout first. Applying permissions as we go would lock a
  # parent before its children exist: secrets becomes 2550 (no owner write), so
  # creating created_by_agent inside it afterwards fails on a fresh machine.
  sudo -u "${AGENT}" mkdir -p \
    "${WORKSPACE_DIR}" \
    "${CREATED_BY_AGENT_SECRETS_DIR}" \
    "${GEMINI_DIR}"

  link_agent_config "${GEMINI_CONFIG_LINK}" "${ADMIN_REPO_CONFIG_DIR}"

  for DOC in "${HANDBOOK_DOCS[@]}"; do
    link_agent_config "${GEMINI_DIR}/${DOC}" "${HANDBOOK_DIR}/${DOC}"
  done
    link_agent_config "${GEMINI_DIR}/AGENTS.md" "${HANDBOOK_DIR}/use-rules-AGENTS.md"


  # Apply outermost-inward so the tighter inner modes are written last and the
  # recursive passes above them cannot undo the modes below.
  apply_agent_home_permission "${AGENT}-home" "${AGENT_DIR}"
  apply_workspace_permissions "${AGENT}-workspace" "${WORKSPACE_DIR}"
  apply_secret_permission "${AGENT}-secrets" "${SECRETS_DIR}"
  apply_agent_secret_permission "${AGENT}-created-by-agent-secrets" "${CREATED_BY_AGENT_SECRETS_DIR}"

  echo "[✓] ${AGENT} initialized successfully."
done

echo "=== All agents processed ==="