#!/usr/bin/env bash
#
# get-gh-token.sh - Generates and persists a GitHub App installation token
# Usage:
#   get-gh-token.sh [-c CLIENT_ID_OR_FILE] [-k KEY_FILE] [-i INSTALLATION_ID] [-t TOKEN_DIR]
#                   [-f|--force] [--no-persist]
#
# Two directories, with deliberately different trust levels:
#   SECRETS_DIR - provisioned input, read only. Holds the App private key and client id.
#   TOKEN_DIR   - agent output, written only by this script. Holds the tokens it retrieves.
#
# Defaults:
#   SECRETS_DIR:     $SECRETS_DIR, else $HOME/secrets/github
#   TOKEN_DIR:       $TOKEN_DIR, else $HOME/secrets/created_by_agent
#   CLIENT_ID:       -c, else $GH_APP_CLIENT_ID, else $SECRETS_DIR/client_id.txt, else $SECRETS_DIR/app_id.txt
#   KEY_FILE:        -k, else $GH_APP_KEY_FILE, else first *.private-key.pem in $SECRETS_DIR
#   INSTALLATION_ID: -i, else $GH_APP_INSTALLATION_ID, else 150712518
#
# Output:
#   Prints the raw token (ghs_...) to stdout, and nothing else. Errors and warnings go to stderr.
#   Unless --no-persist is given, caches the token in $TOKEN_DIR/token.txt and $TOKEN_DIR/token.json.
#
# Token isolation:
#   A token belongs to exactly one agent account and is never shared state. This script therefore
#   refuses to store secrets where another account could reach them, and refuses to hand back a
#   cached token it cannot prove belongs to the calling account and the requested App installation:
#
#     - $TOKEN_DIR must be owned by the calling user, and is forced to mode 0700.
#     - Cached files must be owned by the calling user and unreadable by others, or they are ignored.
#     - A cache entry minted for a different client id or installation id is ignored.
#     - Cache files are opened with O_NOFOLLOW so a planted symlink cannot redirect a read or write.
#     - Writes are atomic (temp file + rename) so concurrent agents cannot observe a torn file.
#
#   $SECRETS_DIR is never written to and is not required to be owned by the calling account, so the
#   key store may be provisioned centrally. Only $TOKEN_DIR holds anything this script creates.
#
#   Callers MUST capture the token into the environment rather than echoing it:
#     export GH_TOKEN="$(./get-gh-token.sh)"

set -euo pipefail
umask 077

SECRETS_DIR="${SECRETS_DIR:-$HOME/secrets/github}"
TOKEN_DIR="${TOKEN_DIR:-$HOME/secrets/created_by_agent}"

CLIENT_ID="${GH_APP_CLIENT_ID:-}"
CLIENT_ID_FILE="${GH_APP_CLIENT_ID_FILE:-}"
KEY_FILE="${GH_APP_KEY_FILE:-}"
INSTALLATION_ID="${GH_APP_INSTALLATION_ID:-150712518}"
FORCE=0
PERSIST=1

usage() {
  echo "Usage: $0 [-c CLIENT_ID_OR_FILE] [-k KEY_FILE] [-i INSTALLATION_ID] [-t TOKEN_DIR] [-f|--force] [--no-persist]"
}

# Every value-taking flag must be followed by a value; without this check `set -u` and
# `shift 2` abort with a raw shell diagnostic instead of a usable message.
require_value() {
  if [[ $# -lt 2 ]]; then
    echo "Error: $1 requires a value." >&2
    exit 1
  fi
}

# Parse CLI arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
    -c|--client-id|--client-id-file)
      require_value "$@"
      if [[ -f "$2" ]]; then
        CLIENT_ID_FILE="$2"
      else
        CLIENT_ID="$2"
      fi
      shift 2
      ;;
    -k|--key|--key-file)
      require_value "$@"
      KEY_FILE="$2"
      shift 2
      ;;
    -i|--installation|--installation-id)
      require_value "$@"
      INSTALLATION_ID="$2"
      shift 2
      ;;
    -t|--token-dir)
      require_value "$@"
      TOKEN_DIR="$2"
      shift 2
      ;;
    -f|--force)
      FORCE=1
      shift 1
      ;;
    --no-persist)
      PERSIST=0
      shift 1
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

# Resolve Client ID
if [[ -z "$CLIENT_ID" ]]; then
  if [[ -n "$CLIENT_ID_FILE" && -f "$CLIENT_ID_FILE" ]]; then
    CLIENT_ID="$(tr -d '\r\n ' < "$CLIENT_ID_FILE")"
  elif [[ -f "$SECRETS_DIR/client_id.txt" ]]; then
    CLIENT_ID="$(tr -d '\r\n ' < "$SECRETS_DIR/client_id.txt")"
  elif [[ -f "$SECRETS_DIR/app_id.txt" ]]; then
    CLIENT_ID="$(tr -d '\r\n ' < "$SECRETS_DIR/app_id.txt")"
  fi
fi

if [[ -z "$CLIENT_ID" ]]; then
  echo "Error: Client ID / App ID not found." >&2
  exit 1
fi

# Resolve Private Key File. Sorted so the choice is deterministic, and restricted to the
# documented suffix so a stray public *.pem can never be selected as a signing key.
if [[ -z "$KEY_FILE" ]]; then
  KEY_FILE="$(find "$SECRETS_DIR" -maxdepth 1 -type f -name "*.private-key.pem" 2>/dev/null | sort | head -n 1 || true)"
fi

if [[ -z "$KEY_FILE" || ! -f "$KEY_FILE" ]]; then
  echo "Error: Private key file not found." >&2
  exit 1
fi

# Generate / retrieve persisted token using Python 3
python3 - "$CLIENT_ID" "$KEY_FILE" "$INSTALLATION_ID" "$TOKEN_DIR" "$FORCE" "$PERSIST" <<'EOF'
import sys, json, time, base64, subprocess, urllib.request, urllib.error, os, tempfile
from datetime import datetime

client_id = sys.argv[1]
key_file = sys.argv[2]
installation_id = sys.argv[3]
# Tokens this script retrieves are written here, and nowhere else. This is not the
# credential store the key was read from — that directory is never written to.
token_dir = sys.argv[4]
force = sys.argv[5] == "1"
persist = sys.argv[6] == "1"

UID = os.getuid()
# Refresh this far ahead of expiry so a token handed out here survives the caller's work.
EXPIRY_MARGIN_SECONDS = 60
# The identity a cached token was minted for. A cache entry that does not match is not ours.
IDENTITY = {"client_id": client_id, "installation_id": str(installation_id)}

token_json_path = os.path.join(token_dir, "token.json")
token_txt_path = os.path.join(token_dir, "token.txt")


def fail(msg):
    sys.stderr.write("Error: %s\n" % msg)
    sys.exit(1)


def warn(msg):
    sys.stderr.write("Warning: %s\n" % msg)


def ensure_private_dir(path):
    """Create/verify the token directory, which only the calling account may reach.

    A token directory owned by someone else is not silently repaired: it means the caller
    was pointed at shared storage, so refuse rather than write a credential into it.
    """
    try:
        os.makedirs(path, mode=0o700, exist_ok=True)
    except OSError as exc:
        fail("cannot create token directory %s: %s" % (path, exc))

    st = os.stat(path)
    if st.st_uid != UID:
        fail(
            "token directory %s is owned by uid %d, not the calling account (uid %d). "
            "Tokens are per-account and must not be stored in shared or foreign locations. "
            "Set TOKEN_DIR to a directory this account owns." % (path, st.st_uid, UID)
        )
    if st.st_mode & 0o077:
        os.chmod(path, 0o700)


def load_cache(path):
    """Return the cached payload only if it provably belongs to this account and identity."""
    try:
        fd = os.open(path, os.O_RDONLY | os.O_NOFOLLOW)
    except OSError:
        return None

    with os.fdopen(fd, "r") as handle:
        st = os.fstat(handle.fileno())
        if st.st_uid != UID:
            warn("ignoring cached token at %s: owned by another account (uid %d)." % (path, st.st_uid))
            return None
        if st.st_mode & 0o077:
            warn("ignoring cached token at %s: reachable by other accounts; treating as compromised." % path)
            return None
        try:
            data = json.load(handle)
        except ValueError:
            return None

    if not isinstance(data, dict):
        return None
    if data.get("_minted_for") != IDENTITY:
        # A token for a different App or installation belongs to a different identity.
        return None
    return data


def write_private(path, text):
    """Atomically write a 0600 file, so concurrent agents never observe a partial token."""
    directory = os.path.dirname(path) or "."
    fd, tmp_path = tempfile.mkstemp(dir=directory, prefix=".tmp-token-")
    try:
        os.fchmod(fd, 0o600)
        with os.fdopen(fd, "w") as handle:
            handle.write(text)
        os.replace(tmp_path, path)
    except BaseException:
        try:
            os.unlink(tmp_path)
        except OSError:
            pass
        raise


ensure_private_dir(token_dir)

try:
    key_st = os.stat(key_file)
    if key_st.st_uid != UID:
        warn("private key %s is owned by uid %d, not this account." % (key_file, key_st.st_uid))
    if key_st.st_mode & 0o077:
        warn("private key %s is reachable by other accounts; run: chmod 600 %s" % (key_file, key_file))
except OSError as exc:
    fail("cannot stat private key %s: %s" % (key_file, exc))

# Reuse a cached token only when it is ours, private, unexpired, and for this identity.
if not force:
    cached = load_cache(token_json_path)
    if cached:
        exp_str = cached.get("expires_at")
        token = cached.get("token")
        if token and exp_str:
            try:
                exp_dt = datetime.fromisoformat(exp_str.replace("Z", "+00:00"))
            except ValueError:
                exp_dt = None
            if exp_dt and exp_dt.timestamp() - time.time() > EXPIRY_MARGIN_SECONDS:
                print(token)
                sys.exit(0)


def b64url(data):
    if isinstance(data, str):
        data = data.encode("utf-8")
    return base64.urlsafe_b64encode(data).decode("utf-8").rstrip("=")


now = int(time.time())
header = {"alg": "RS256", "typ": "JWT"}
payload = {
    "iat": now - 60,
    "exp": now + 600,
    "iss": client_id
}

hdr_b64 = b64url(json.dumps(header))
pld_b64 = b64url(json.dumps(payload))
to_sign = f"{hdr_b64}.{pld_b64}"

proc = subprocess.Popen(
    ["openssl", "dgst", "-sha256", "-sign", key_file],
    stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.PIPE
)
sig, err = proc.communicate(input=to_sign.encode("utf-8"))

if proc.returncode != 0:
    sys.stderr.write(f"OpenSSL error: {err.decode()}\n")
    sys.exit(1)

jwt = f"{to_sign}.{b64url(sig)}"

url = f"https://api.github.com/app/installations/{installation_id}/access_tokens"
req = urllib.request.Request(url, method="POST")
req.add_header("Authorization", f"Bearer {jwt}")
req.add_header("Accept", "application/vnd.github+json")
req.add_header("User-Agent", "Antigravity-Agent")

try:
    with urllib.request.urlopen(req) as resp:
        res = json.loads(resp.read().decode())
        token = res.get("token")
        if not token:
            sys.stderr.write("Error: Response did not contain access token\n")
            sys.exit(1)

        if persist:
            res["_minted_for"] = IDENTITY
            write_private(token_json_path, json.dumps(res, indent=2))
            write_private(token_txt_path, token + "\n")

        print(token)
except urllib.error.HTTPError as e:
    sys.stderr.write(f"GitHub API Error: {e.code} {e.read().decode()}\n")
    sys.exit(1)
except Exception as e:
    sys.stderr.write(f"Error: {e}\n")
    sys.exit(1)
EOF
