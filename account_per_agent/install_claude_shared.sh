#!/usr/bin/env bash
set -euo pipefail

# Publishes one admin-owned copy of the Claude Code binary that every agent
# account runs, and registers it on PATH for all users.
#
# Claude Code's own installer is strictly $HOME-based (it hardcodes
# $HOME/.local/share/claude and $HOME/.claude/downloads), so there is no
# supported system-wide install mode. What it produces, however, is a single
# self-contained executable that reads all of its state from $HOME/.claude at
# run time. That makes the binary itself relocatable: one copy in a shared,
# admin-owned location serves every account, while each agent keeps its own
# private config and credentials under its own home.
#
# The shared copy is the only one kept. Publishing needs a binary to copy from,
# so the admin owner installs one, runs this, and deletes it again:
#
#   curl -fsSL https://claude.ai/install.sh | bash
#   install_claude_shared.sh
#   rm -rf ~/.local/share/claude ~/.local/bin/claude
#
# That is also the upgrade path -- there is no persistent private install to
# run `claude update` against.

fail() {
  echo "$*" >&2
  exit 1
}

OS_NAME="$(uname -s)"
[[ "${OS_NAME}" == "Darwin" ]] || fail "This script targets macOS; got ${OS_NAME}"

DEVELOPERS_GROUP="${DEVELOPERS_GROUP:-developers}"
ADMINS_GROUP="${ADMINS_GROUP:-admin}"

# Mirrors setup.sh: the shared tree is owned by the one account that is in both
# the developers and admin groups, and is read-only to every other developer.
SHARED_ROOT="${CLAUDE_SHARED_ROOT:-/Users/Shared/tools/claude}"
SHARED_BIN_DIR="${SHARED_ROOT}/bin"
SHARED_BIN="${SHARED_BIN_DIR}/claude"

PATHS_D_NAME="claude"
PATHS_D_FILE="/etc/paths.d/${PATHS_D_NAME}"
ZSHENV_FILE="/etc/zshenv"
BLOCK_BEGIN="# >>> claude shared install (managed by install_claude_shared.sh) >>>"
BLOCK_END="# <<< claude shared install (managed by install_claude_shared.sh) <<<"

user_in_group() {
  id -Gn "$1" 2>/dev/null | tr ' ' '\n' | grep -qx "$2"
}

# Same derivation as setup.sh, so both scripts agree on who the admin owner is
# without either hardcoding an account name.
resolve_admin_owner() {
  local user
  local found=""
  local count=0

  for user in $(dscl . -list /Users 2>/dev/null); do
    user_in_group "${user}" "${DEVELOPERS_GROUP}" || continue
    user_in_group "${user}" "${ADMINS_GROUP}" || continue
    found="${found:+${found} }${user}"
    count=$((count + 1))
  done

  (( count == 1 )) || fail "Expected exactly one ${DEVELOPERS_GROUP}+${ADMINS_GROUP} account, found ${count} (${found:-none}); set ADMIN_OWNER explicitly"
  ADMIN_OWNER="${found}"
  echo "Discovered ADMIN_OWNER: ${ADMIN_OWNER}"
}

[[ -n "${ADMIN_OWNER:-}" ]] || resolve_admin_owner
[[ "${ADMIN_OWNER}" =~ ^[a-z_][a-z0-9_-]*$ ]] || fail "Invalid account name: ${ADMIN_OWNER}"
id -u "${ADMIN_OWNER}" >/dev/null 2>&1 || fail "User does not exist: ${ADMIN_OWNER}"

ADMIN_HOME="$(dscl . -read "/Users/${ADMIN_OWNER}" NFSHomeDirectory 2>/dev/null | awk '{print $2}')"
[[ -d "${ADMIN_HOME}" ]] || fail "Cannot resolve home directory for ${ADMIN_OWNER}"

# The installer maintains ~/.local/bin/claude as a symlink to the versioned
# binary it just unpacked, so following it is what identifies the current
# version -- reading the versions directory would need a sort and would pick
# wrongly after a downgrade.
SOURCE_LINK="${ADMIN_HOME}/.local/bin/claude"
[[ -L "${SOURCE_LINK}" || -f "${SOURCE_LINK}" ]] \
  || fail "No Claude Code install found for ${ADMIN_OWNER} at ${SOURCE_LINK}; run the installer as ${ADMIN_OWNER} first"

SOURCE_BIN="$(cd -P "$(dirname "${SOURCE_LINK}")" && readlink "${SOURCE_LINK}" || true)"
[[ -n "${SOURCE_BIN}" ]] || SOURCE_BIN="${SOURCE_LINK}"
[[ -f "${SOURCE_BIN}" ]] || fail "Install symlink does not resolve to a file: ${SOURCE_BIN}"

VERSION="$(basename "${SOURCE_BIN}")"
echo "Source: ${SOURCE_BIN} (version ${VERSION})"

if [[ -L "${SHARED_BIN_DIR}" || -L "${SHARED_ROOT}" ]]; then
  fail "Refusing to install through a symlink: ${SHARED_ROOT}"
fi

sudo mkdir -p "${SHARED_BIN_DIR}"

# Copy to a temporary name in the same directory and rename into place. A plain
# `cp` over the destination writes through the existing inode, which corrupts
# the image of any agent currently executing it; rename() swaps the directory
# entry instead, so running processes keep the old inode until they exit.
# Same-directory is what makes the rename atomic -- across filesystems it would
# degrade to a copy.
STAGING="${SHARED_BIN_DIR}/.claude.incoming.$$"
cleanup() { sudo rm -f "${STAGING}"; }
trap cleanup EXIT

sudo cp "${SOURCE_BIN}" "${STAGING}"
sudo chown "${ADMIN_OWNER}:${DEVELOPERS_GROUP}" "${STAGING}"
sudo chmod 0750 "${STAGING}"
sudo mv -f "${STAGING}" "${SHARED_BIN}"
trap - EXIT

# Matches apply_scripts_permission in setup.sh: admin owns, developers read and
# execute, everyone else gets nothing. setgid keeps anything added later in the
# developers group.
sudo chown "${ADMIN_OWNER}:${DEVELOPERS_GROUP}" "${SHARED_ROOT}" "${SHARED_BIN_DIR}"
sudo chmod 2750 "${SHARED_ROOT}" "${SHARED_BIN_DIR}"

echo "Installed: ${SHARED_BIN}"

# Same mechanism as register_on_path in setup.sh. path_helper reads this for
# login shells, which is how the agents already pick up agent-scripts and
# gcloud. Note it does not expand ~, so the path must be absolute.
printf '%s\n' "${SHARED_BIN_DIR}" | sudo tee "${PATHS_D_FILE}" >/dev/null
sudo chown root:wheel "${PATHS_D_FILE}"
sudo chmod 0644 "${PATHS_D_FILE}"
echo "Registered on PATH: ${PATHS_D_FILE}"

# The auto-updater rewrites the directory holding the binary, which only the
# admin owner can do. Agents would retry and warn on every start, so it is
# switched off for them.
#
# The test is write access to the install directory rather than an account name
# or group: that is precisely the condition the updater needs, so the guard
# stays correct on its own if ownership ever moves. Today it is true only for
# the admin owner.
#
# /etc/zshenv rather than /etc/zprofile because zshenv is sourced for every zsh
# invocation, not just login shells -- an agent spawned non-interactively still
# gets it. It is also why the guard is a single stat and not a subprocess.
ZSHENV_BLOCK="$(cat <<EOF
${BLOCK_BEGIN}
# Agents run the shared, admin-owned Claude Code install and cannot write it,
# so the auto-updater is disabled for them. The owner keeps it enabled and
# publishes new versions with install_claude_shared.sh.
if [ ! -w "${SHARED_BIN_DIR}" ]; then
  export DISABLE_AUTOUPDATER=1
fi
${BLOCK_END}
EOF
)"

# Rewrite only our own block, so anything else in the file survives a re-run.
EXISTING=""
[[ -f "${ZSHENV_FILE}" ]] && EXISTING="$(sudo cat "${ZSHENV_FILE}")"
REMAINDER="$(printf '%s\n' "${EXISTING}" | awk -v b="${BLOCK_BEGIN}" -v e="${BLOCK_END}" '
  $0 == b { skip = 1; next }
  $0 == e { skip = 0; next }
  !skip   { print }
')"

printf '%s\n%s\n' "$(printf '%s' "${REMAINDER}" | sed -e :a -e '/^\n*$/{$d;N;ba' -e '}')" "${ZSHENV_BLOCK}" \
  | sudo tee "${ZSHENV_FILE}" >/dev/null
sudo chown root:wheel "${ZSHENV_FILE}"
sudo chmod 0644 "${ZSHENV_FILE}"
echo "Auto-updater guard written: ${ZSHENV_FILE}"

echo "=== Done: claude ${VERSION} published to ${SHARED_BIN} ==="
