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

# Linked as GEMINI.md, the name the CLI loads automatically, so the link name
# differs from the source name and it cannot live in HANDBOOK_DOCS above. Named
# here so the permission and ACL passes cover it too.
AGENTS_DOC_SOURCE="use-rules-AGENTS.md"
AGENTS_DOC_LINK_NAME="GEMINI.md"

# Names this script used for the same document in earlier revisions. Removed on
# every run so a rename here cannot leave the agent reading two copies, one of
# them stale.
LEGACY_DOC_LINK_NAMES=(
  "AGENTS.md"
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

# The links this script drops in ~/.gemini are root-owned, but that alone does
# not protect them: on POSIX it is write permission on the *containing
# directory* that governs unlink and rename, not ownership of the entry. An
# agent owning ~/.gemini can therefore delete a rules link and substitute its
# own file, detaching itself from the rules it is meant to run under -- without
# ever needing write access to the config tree.
#
# Handing the directory to ADMIN_OWNER and setting the sticky bit closes that
# without locking the agent out of its own config directory: group write still
# lets the agent create files here (the CLI keeps session state alongside the
# links), while +t restricts unlink and rename of an existing entry to that
# entry's owner. For the links, that is root. Re-runs are unaffected, since
# link_agent_config removes them as root.
apply_agent_config_dir_permission() {
  local description="$1"
  local target="$2"

  assert_not_symlink "${description}" "${target}"

  sudo chown "${ADMIN_OWNER}:${DEVELOPERS_GROUP}" "${target}"
  sudo chmod 1775 "${target}"
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

# Grant DEVELOPERS_GROUP read access that survives mode drift on the link target.
#
# The handbook is a git working tree, so `git checkout`/`pull`/`stash` replace a
# document's inode rather than editing it in place. The replacement takes its
# mode from the writing process's umask, which silently discards the 0640 set by
# apply_admin_workspace_permission and can leave every agent's symlink pointing
# at a file it can no longer open. Mode bits do not inherit, so re-running this
# script is the only thing that repairs them -- and only until the next checkout.
#
# An ACL placed on the *directory* does inherit: the kernel reapplies it to each
# file created there afterwards, whatever the umask or the writing user. That
# makes agent readability independent of the mode entirely. The named files are
# also granted directly, to cover a bare chmod that leaves the inode in place.
#
# Both forms are idempotent -- re-adding an existing ACE is a no-op, not a
# duplicate -- so this is safe on every re-run.
grant_inherited_group_read() {
  local dir="$1"
  shift

  assert_not_symlink "inherited-read-acl" "${dir}"

  local file
  case "${OS_NAME}" in
    Darwin)
      # file_inherit only: every linked document sits at the top level of the
      # handbook, so there is no reason to propagate into subdirectories (and
      # every reason not to recurse into .git).
      sudo chmod +a "group:${DEVELOPERS_GROUP} allow list,search,readattr,readextattr,readsecurity,file_inherit" "${dir}"
      for file in "$@"; do
        sudo chmod +a "group:${DEVELOPERS_GROUP} allow read,readattr,readextattr,readsecurity" "${file}"
      done
      ;;
    Linux)
      # The `d:` entry is the default ACL, applied to newly created files only;
      # the plain entry covers the directory itself.
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

# Build a real ~/.gemini/config tree for one agent: directories are created, and
# every file is hard-linked back to the one in the admin repo.
#
# A symlinked config directory is not traversed by the agent CLI, so the tree has
# to consist of real directory entries. Only the leaf files are links, and they
# are symbolic: a symlink resolves by path, so it still points at the right file
# after `git checkout`, `git pull`, or an editor's atomic save replaces the
# source. Hard links would not -- they track the inode, and every one of those
# operations creates a new one, silently leaving the agent on a frozen copy of
# the old contents. Nothing in git can be configured to write in place.
#
# The tradeoff runs the other way for discovery: a symlink is not reported as a
# regular file by a `readdir`-based scan that filters on `isFile()`. That is why
# the directories are real -- the CLI has to be able to walk the tree -- while
# the files, which it opens by path, can be links.
mirror_config_tree() {
  local src="$1"
  local dest="$2"
  local rel

  # A previous revision made this path a symlink; remove it before it can be
  # mistaken for a directory to recurse into.
  if [[ -L "${dest}" ]]; then
    sudo rm -f "${dest}"
  fi

  case "${dest}" in
    "${BASE_DIR}"/*/.gemini/config) : ;;
    *) fail "Refusing to rebuild unexpected agent config path: ${dest}" ;;
  esac

  sudo mkdir -p "${dest}"

  # Every leaf this script owns is a symlink, so clearing them all and recreating
  # them below leaves nothing behind from a file since deleted in the admin repo.
  #
  # This is deliberately not an rm -rf of the tree: projects/ holds the agent's
  # own work and has to survive a re-run, so it is pruned here and its contents
  # are never touched. The cost is that a directory removed from the admin repo
  # lingers as an empty directory until someone deletes it by hand -- cheap, next
  # to discarding an agent's project state on every provisioning run.
  sudo find "${dest}" -path "${dest}/projects" -prune -o -type l -delete

  # Directories first: a file must never precede its parent. -L classifies by
  # what a link points at, so a symlink added to the admin repo is recreated here
  # as a link to the same file rather than as a link to a link.
  while IFS= read -r rel; do
    sudo mkdir -p "${dest}/${rel}"
  done < <(cd "${src}" && find -L . -mindepth 1 -type d | sed 's|^\./||')

  while IFS= read -r rel; do
    sudo ln -s "${src}/${rel}" "${dest}/${rel}"
  done < <(cd "${src}" && find -L . -mindepth 1 -type f | sed 's|^\./||')
}

# The rules are handbook documents, not config-tree files, so they are linked
# straight from the handbook into the top level of ~/.gemini, where the CLI reads
# them. The admin repo holds no copy of them and needs none: the handbook is the
# source.
#
# link_agent_config rather than a bare `ln -s`: these sit outside the config tree
# and so are not cleared by the rebuild sweep, meaning a second run would hit an
# existing link. It replaces one and refuses to clobber a real file.
link_agent_rules() {
  local dest="$1"
  local doc

  sudo mkdir -p "${dest}"

  for doc in "${HANDBOOK_DOCS[@]}"; do
    link_agent_config "${dest}/${doc}" "${HANDBOOK_DIR}/${doc}"
  done
  link_agent_config "${dest}/${AGENTS_DOC_LINK_NAME}" "${HANDBOOK_DIR}/${AGENTS_DOC_SOURCE}"

  for doc in "${LEGACY_DOC_LINK_NAMES[@]}"; do
    if [[ -L "${dest}/${doc}" ]]; then
      sudo rm -f "${dest}/${doc}"
    fi
  done
}

# Only the directories, which is what governs whether an agent can add or remove
# entries. The leaf files are symlinks and deliberately left alone: chmod and
# chown follow a symlink to its target, so a recursive pass here would reach out
# of the agent's tree and rewrite the admin repo and handbook originals --
# stripping the executable bit from get-gh-token.sh among other things. A
# symlink's own mode is not consulted for access anyway; the target's is, and
# that is set where the target lives.
#
# projects/ is pruned throughout: it belongs to the agent, and a recursive pass
# would take their own project directories away from them.
apply_agent_config_mirror_permission() {
  local description="$1"
  local target="$2"

  assert_not_symlink "${description}" "${target}"

  sudo find "${target}" -path "${target}/projects" -prune -o \
    -type d -exec chown "${ADMIN_OWNER}:${DEVELOPERS_GROUP}" {} +
  sudo find "${target}" -path "${target}/projects" -prune -o \
    -type d -exec chmod 2750 {} +
}

# The one place under config the agent owns outright. Everything else is
# admin-owned and read-only to them; project state is theirs to write, so the
# directory is handed over rather than mirrored. Only the directory itself is
# touched -- whatever the agent has created inside it is already theirs, and a
# recursive pass would only risk disturbing it.
apply_agent_projects_permission() {
  local description="$1"
  local target="$2"

  assert_not_symlink "${description}" "${target}"

  sudo chown "${AGENT}:${DEVELOPERS_GROUP}" "${target}"
  # setgid so anything created here stays in the developers group, keeping it
  # readable to the admin owner without a chown after the fact.
  sudo chmod 2770 "${target}"
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
LINKED_DOC_PATHS=()
for DOC in "${HANDBOOK_DOCS[@]}" "${AGENTS_DOC_SOURCE}"; do
  DOC_PATH="${HANDBOOK_DIR}/${DOC}"
  [[ -f "${DOC_PATH}" ]] || fail "Handbook document not found: ${DOC_PATH}"
  apply_admin_workspace_permission "handbook-${DOC}" "${DOC_PATH}"
  LINKED_DOC_PATHS+=("${DOC_PATH}")
done

# The chmod above fixes the modes as they are now; this keeps them irrelevant
# from here on, so a later `git checkout` in the handbook cannot lock agents out
# of a document they hold a link to.
grant_inherited_group_read "${HANDBOOK_DIR}" "${LINKED_DOC_PATHS[@]}"
grant_inherited_group_read "${ADMIN_REPO_CONFIG_DIR}"

for AGENT in "${AGENT_NAMES[@]}"; do
  AGENT_DIR="${BASE_DIR}/${AGENT}"
  WORKSPACE_DIR="${AGENT_DIR}/workspace"
  SECRETS_DIR="${AGENT_DIR}/secrets"
  CREATED_BY_AGENT_SECRETS_DIR="${SECRETS_DIR}/created_by_agent"
  GEMINI_DIR="${AGENT_DIR}/.gemini"
  GEMINI_CONFIG_DIR="${GEMINI_DIR}/config"
  GEMINI_PROJECTS_DIR="${GEMINI_CONFIG_DIR}/projects"
  # Left behind by the revision that kept the rules under the config tree.
  LEGACY_RULES_DIR="${GEMINI_CONFIG_DIR}/rules"

  echo "[+] Processing: ${AGENT}"

  # Create the whole layout first. Applying permissions as we go would lock a
  # parent before its children exist: secrets becomes 2550 (no owner write), so
  # creating created_by_agent inside it afterwards fails on a fresh machine.
  sudo -u "${AGENT}" mkdir -p \
    "${WORKSPACE_DIR}" \
    "${CREATED_BY_AGENT_SECRETS_DIR}" \
    "${GEMINI_DIR}"

  mirror_config_tree "${ADMIN_REPO_CONFIG_DIR}" "${GEMINI_CONFIG_DIR}"
  link_agent_rules "${GEMINI_DIR}"
  # mkdir -p, never recreated: the rebuild above prunes it, so an existing
  # projects directory keeps its contents across runs.
  sudo mkdir -p "${GEMINI_PROJECTS_DIR}"

  # The rebuild sweep already removed the links this directory held. rmdir, not
  # rm -r, so it goes only if it is genuinely empty and anything unexpected left
  # inside is preserved for inspection rather than deleted.
  sudo rmdir "${LEGACY_RULES_DIR}" 2>/dev/null || true


  # Apply outermost-inward so the tighter inner modes are written last and the
  # recursive passes above them cannot undo the modes below.
  apply_agent_home_permission "${AGENT}-home" "${AGENT_DIR}"
  apply_agent_config_dir_permission "${AGENT}-gemini" "${GEMINI_DIR}"
  apply_agent_config_mirror_permission "${AGENT}-gemini-config" "${GEMINI_CONFIG_DIR}"
  apply_agent_projects_permission "${AGENT}-gemini-projects" "${GEMINI_PROJECTS_DIR}"
  apply_workspace_permissions "${AGENT}-workspace" "${WORKSPACE_DIR}"
  apply_secret_permission "${AGENT}-secrets" "${SECRETS_DIR}"
  apply_agent_secret_permission "${AGENT}-created-by-agent-secrets" "${CREATED_BY_AGENT_SECRETS_DIR}"

  echo "[✓] ${AGENT} initialized successfully."
done

echo "=== All agents processed ==="