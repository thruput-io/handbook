#!/usr/bin/env bash
#
# get-gh-token.sh - Generates and persists a GitHub App installation token
# Usage:
#   get-gh-token.sh [-c CLIENT_ID_OR_FILE] [-k KEY_FILE] [-i INSTALLATION_ID] [-f|--force]
#
# Defaults:
#   SECRETS_DIR:     $HOME/secrets/github or $SECRETS_DIR
#   CLIENT_ID:       $SECRETS_DIR/client_id.txt or $GH_APP_CLIENT_ID
#   KEY_FILE:        First *.private-key.pem in $SECRETS_DIR or $GH_APP_KEY_FILE
#   INSTALLATION_ID: 150712518 or $GH_APP_INSTALLATION_ID
#
# Output:
#   Prints raw token (ghs_...) to stdout. Persists token in $SECRETS_DIR/token.txt and $SECRETS_DIR/token.json.
#   Errors go to stderr.

set -euo pipefail

SECRETS_DIR="${SECRETS_DIR:-$HOME/secrets/github}"

CLIENT_ID="${GH_APP_CLIENT_ID:-}"
CLIENT_ID_FILE="${GH_APP_CLIENT_ID_FILE:-}"
KEY_FILE="${GH_APP_KEY_FILE:-}"
INSTALLATION_ID="${GH_APP_INSTALLATION_ID:-150712518}"
FORCE=0

# Parse CLI arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
    -c|--client-id|--client-id-file)
      if [[ -f "$2" ]]; then
        CLIENT_ID_FILE="$2"
      else
        CLIENT_ID="$2"
      fi
      shift 2
      ;;
    -k|--key|--key-file)
      KEY_FILE="$2"
      shift 2
      ;;
    -i|--installation|--installation-id)
      INSTALLATION_ID="$2"
      shift 2
      ;;
    -f|--force)
      FORCE=1
      shift 1
      ;;
    -h|--help)
      echo "Usage: $0 [-c CLIENT_ID_OR_FILE] [-k KEY_FILE] [-i INSTALLATION_ID] [-f|--force]"
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      exit 1
      ;;
  esac
done

# Resolve Client ID
if [[ -z "$CLIENT_ID" ]]; then
  if [[ -n "$CLIENT_ID_FILE" && -f "$CLIENT_ID_FILE" ]]; then
    CLIENT_ID="$(cat "$CLIENT_ID_FILE" | tr -d '\r\n ')"
  elif [[ -f "$SECRETS_DIR/client_id.txt" ]]; then
    CLIENT_ID="$(cat "$SECRETS_DIR/client_id.txt" | tr -d '\r\n ')"
  elif [[ -f "$SECRETS_DIR/app_id.txt" ]]; then
    CLIENT_ID="$(cat "$SECRETS_DIR/app_id.txt" | tr -d '\r\n ')"
  fi
fi

if [[ -z "$CLIENT_ID" ]]; then
  echo "Error: Client ID / App ID not found." >&2
  exit 1
fi

# Resolve Private Key File
if [[ -z "$KEY_FILE" ]]; then
  KEY_FILE="$(find "$SECRETS_DIR" -maxdepth 1 -type f \( -name "*.private-key.pem" -o -name "*.pem" \) | head -n 1 2>/dev/null || true)"
fi

if [[ -z "$KEY_FILE" || ! -f "$KEY_FILE" ]]; then
  echo "Error: Private key file not found." >&2
  exit 1
fi

# Generate / retrieve persisted token using Python 3
python3 - "$CLIENT_ID" "$KEY_FILE" "$INSTALLATION_ID" "$SECRETS_DIR" "$FORCE" <<'EOF'
import sys, json, time, base64, subprocess, urllib.request, os
from datetime import datetime, timezone

client_id = sys.argv[1]
key_file = sys.argv[2]
installation_id = sys.argv[3]
secrets_dir = sys.argv[4]
force = sys.argv[5] == "1"

token_json_path = os.path.join(secrets_dir, "token.json")
token_txt_path = os.path.join(secrets_dir, "token.txt")

# Check if persisted cached token is valid
if not force and os.path.exists(token_json_path):
    try:
        with open(token_json_path, "r") as f:
            cached_data = json.load(f)
        exp_str = cached_data.get("expires_at")
        token = cached_data.get("token")
        if token and exp_str:
            exp_dt = datetime.fromisoformat(exp_str.replace("Z", "+00:00"))
            if exp_dt.timestamp() - time.time() > 60:
                print(token)
                sys.exit(0)
    except Exception:
        pass  # If reading cache fails, proceed to generate new token

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
        
        # Persist token to ~/secrets/github/ directory
        os.makedirs(secrets_dir, exist_ok=True)
        with open(token_json_path, "w") as f:
            json.dump(res, f, indent=2)
        with open(token_txt_path, "w") as f:
            f.write(token + "\n")

        print(token)
except Exception as e:
    if hasattr(e, "read"):
        sys.stderr.write(f"GitHub API Error: {e.code} {e.read().decode()}\n")
    else:
        sys.stderr.write(f"Error: {e}\n")
    sys.exit(1)
EOF
