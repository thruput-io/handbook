#!/usr/bin/env bash

OS_NAME="$(uname -s)"
DEVELOPERS_GROUP="${DEVELOPERS_GROUP:-developers}"

case "${OS_NAME}" in
  Darwin)
    BASE_DIR="${AGENT_HOME_BASE:-/Users}"
    ADMINS_GROUP="${ADMINS_GROUP:-admin}"
    ROOT_GROUP="wheel"
    MANAGED_SETTINGS_DIR="/Library/Application Support/ClaudeCode"
    ;;
  Linux)
    BASE_DIR="${AGENT_HOME_BASE:-/home}"
    ADMINS_GROUP="${ADMINS_GROUP:-sudo}"
    ROOT_GROUP="root"
    MANAGED_SETTINGS_DIR="/etc/claude-code"
    ;;
  *)
    echo "Unsupported platform: $(uname -s) (supported: Darwin, Linux)" >&2
    exit 2
    ;;
esac

fail() {
  echo "$*" >&2
  exit 1
}

list_all_users() {
  case "${OS_NAME}" in
    Darwin) dscl . -list /Users 2>/dev/null ;;
    Linux)  getent passwd | cut -d: -f1 ;;
  esac
}

user_in_group() {
  id -Gn "$1" 2>/dev/null | tr ' ' '\n' | grep -qx "$2"
}

home_of() {
  local account="$1"
  case "${OS_NAME}" in
    Darwin) dscl . -read "/Users/${account}" NFSHomeDirectory 2>/dev/null | sed 's/^NFSHomeDirectory: //' ;;
    Linux)  getent passwd "${account}" | cut -d: -f6 ;;
  esac
}

resolve_identities() {
  local account admins="" agents=""

  for account in $(list_all_users); do
    user_in_group "${account}" "${DEVELOPERS_GROUP}" || continue
    if user_in_group "${account}" "${ADMINS_GROUP}"; then
      admins="${admins:+${admins} }${account}"
    else
      agents="${agents:+${agents} }${account}"
    fi
  done

  ADMIN_OWNER="${ADMIN_OWNER:-${admins}}"
  AGENTS="${AGENTS:-${agents}}"

  [[ -n "${ADMIN_OWNER}" ]] \
    || fail "No account is in both ${DEVELOPERS_GROUP} and ${ADMINS_GROUP}; set ADMIN_OWNER explicitly"
  [[ "${ADMIN_OWNER}" != *" "* ]] \
    || fail "Several accounts are in both ${DEVELOPERS_GROUP} and ${ADMINS_GROUP} (${ADMIN_OWNER}); set ADMIN_OWNER explicitly"
}

require_agents() {
  [[ -n "${AGENTS:-}" ]] \
    || fail "No ${DEVELOPERS_GROUP} members outside ${ADMINS_GROUP} found; nothing to do"
}

assert_user_exists() {
  local account="$1"
  [[ "${account}" =~ ^[a-z_][a-z0-9_-]*$ ]] || fail "Invalid account name: ${account}"
  id -u "${account}" >/dev/null 2>&1 || fail "User does not exist: ${account}"
}

assert_group_exists() {
  local group="$1"
  case "${OS_NAME}" in
    Darwin) dscl . -read "/Groups/${group}" >/dev/null 2>&1 ;;
    Linux)  getent group "${group}" >/dev/null 2>&1 ;;
  esac || fail "Group does not exist: ${group}"
}
