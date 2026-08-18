#!/usr/bin/env bash
set -euo pipefail

LIB_DIR="$(cd -P "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
. "${LIB_DIR}/lib.sh"

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


# Mirrors setup.sh: the shared tree is owned by the one account that is in both
# the developers and admin groups, and is read-only to every other developer.
case "${OS_NAME}" in
  Darwin) DEFAULT_SHARED_ROOT="/Users/Shared/tools/claude" ;;
  Linux)  DEFAULT_SHARED_ROOT="/srv/tools/claude" ;;
esac

SHARED_ROOT="${CLAUDE_SHARED_ROOT:-${DEFAULT_SHARED_ROOT}}"
SHARED_BIN_DIR="${SHARED_ROOT}/bin"
SHARED_BIN="${SHARED_BIN_DIR}/claude"



resolve_identities
[[ "${ADMIN_OWNER}" =~ ^[a-z_][a-z0-9_-]*$ ]] || fail "Invalid account name: ${ADMIN_OWNER}"
id -u "${ADMIN_OWNER}" >/dev/null 2>&1 || fail "User does not exist: ${ADMIN_OWNER}"

ADMIN_HOME="$(home_of "${ADMIN_OWNER}")"
[[ -d "${ADMIN_HOME}" ]] || fail "Cannot resolve home directory for ${ADMIN_OWNER}"

# The installer maintains ~/.local/bin/claude as a symlink to the versioned
# binary it just unpacked, so following it is what identifies the current
# version -- reading the versions directory would need a sort and would pick
# wrongly after a downgrade.
SOURCE_LINK="${ADMIN_HOME}/.local/bin/claude"
[[ -L "${SOURCE_LINK}" || -f "${SOURCE_LINK}" ]] \
  || fail "No Claude Code install found for ${ADMIN_OWNER} at ${SOURCE_LINK}; run the installer as ${ADMIN_OWNER} first"

# No fallback to the link path itself when readlink fails. Following the link
# is what identifies the version -- the installer names each binary after it --
# so a path that is not such a link carries no version to read. Substituting it
# does not degrade gracefully: VERSION becomes basename("<...>/bin/claude"),
# the literal string "claude", and the run ends with "Done: claude claude
# published". The admin is told a publish succeeded and cannot see what shipped.
[[ -L "${SOURCE_LINK}" ]] \
  || fail "${SOURCE_LINK} is not a symlink. The installer maintains it as one, pointing at the versioned binary; a plain file there carries no version to publish."

SOURCE_BIN="$(cd -P "$(dirname "${SOURCE_LINK}")" && readlink "${SOURCE_LINK}")" \
  || fail "Cannot resolve the install symlink: ${SOURCE_LINK}"
[[ -f "${SOURCE_BIN}" ]] || fail "Install symlink does not resolve to a file: ${SOURCE_BIN}"

# The admin owner may keep a launcher symlink at ~/.local/bin/claude pointing at
# the shared copy, so that `claude doctor` does not report the path as broken.
# That makes this script's source resolve to its own destination: it would stage
# the shared binary, rename it over itself, and report a successful publish
# having shipped nothing. An admin who ran this expecting to roll out a new
# version would be told it worked.
#
# Compared physically, since either path may itself be reached through a link.
if [[ "$(cd -P "$(dirname "${SOURCE_BIN}")" && pwd -P)/$(basename "${SOURCE_BIN}")" \
   == "$(cd -P "$(dirname "${SHARED_BIN}")" 2>/dev/null && pwd -P)/$(basename "${SHARED_BIN}")" ]]; then
  fail "Source resolves to the shared copy itself (${SOURCE_BIN}).
${ADMIN_OWNER}'s ~/.local/bin/claude is a launcher pointing here, not a real install.
Install a version first, then re-run:
  curl -fsSL https://claude.ai/install.sh | bash"
fi

VERSION="$(basename "${SOURCE_BIN}")"

# The version is reported to the admin and is the only signal that the intended
# build shipped, so it is checked rather than trusted: anything that is not a
# version number means the source was resolved wrongly, and publishing under a
# meaningless label is worse than not publishing.
[[ "${VERSION}" =~ ^[0-9]+\.[0-9]+\.[0-9]+ ]] \
  || fail "Source does not name a version (got '${VERSION}' from ${SOURCE_BIN}); refusing to publish"
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

# Same mechanism as register_on_path in setup.sh: a drop-in the login shell
# already reads, which is how the agents pick up agent-scripts and gcloud.
# Neither form expands ~, so the path must be absolute.
case "${OS_NAME}" in
  Darwin)
    PATH_REGISTRATION="/etc/paths.d/claude"
    printf '%s\n' "${SHARED_BIN_DIR}" | sudo tee "${PATH_REGISTRATION}" >/dev/null
    ;;
  Linux)
    PATH_REGISTRATION="/etc/profile.d/claude.sh"
    printf 'PATH="%s:${PATH}"\n' "${SHARED_BIN_DIR}" | sudo tee "${PATH_REGISTRATION}" >/dev/null
    ;;
esac

sudo chown "root:${ROOT_GROUP}" "${PATH_REGISTRATION}"
sudo chmod 0644 "${PATH_REGISTRATION}"
echo "Registered on PATH: ${PATH_REGISTRATION}"

# The auto-updater is disabled for every account, the admin owner included.
#
# It is not a preference. The updater has no install location of its own: it
# maintains $HOME/.local/share/claude, so any account that runs it acquires a
# private ~300MB copy of the CLI and starts running that instead of the shared
# one. Leaving it enabled anywhere means a private install exists there, and
# deleting that install only lasts until the next session starts.
#
# The cost is that updates are manual -- install, publish, delete, as the
# header describes -- and that is the intended trade: exactly one copy of the
# binary exists on this machine, and every account runs it.
#
MANAGED_SETTINGS="${MANAGED_SETTINGS_DIR}/managed-settings.json"

sudo mkdir -p "${MANAGED_SETTINGS_DIR}"

# DISABLE_UPDATES, not DISABLE_AUTOUPDATER. The latter only stops the background
# check: a manual `claude update` still runs and -- measured on this fleet --
# still writes a full private install under ~/.local/share/claude even when it
# concludes the account is already current. DISABLE_UPDATES refuses outright.
printf '%s\n' '{' '  "env": {' '    "DISABLE_UPDATES": "1"' '  }' '}' \
  | sudo tee "${MANAGED_SETTINGS}" >/dev/null
sudo chown root:wheel "${MANAGED_SETTINGS}"
sudo chmod 0644 "${MANAGED_SETTINGS}"
echo "Update guard written: ${MANAGED_SETTINGS}"

echo "=== Done: claude ${VERSION} published to ${SHARED_BIN} ==="
