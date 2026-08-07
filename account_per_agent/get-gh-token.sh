#!/usr/bin/env bash
set -euo pipefail

CLIENT_ID="$(tr -d '\r\n ' < "$HOME/secrets/github/client_id.txt")"
INSTALLATION_ID="$(tr -d '\r\n ' < "$HOME/secrets/github/installation_id.txt")"
KEY_FILE="$HOME/secrets/github/private_key.pem"

NOW=$(date +%s)
IAT=$((NOW - 60))
EXP=$((NOW + 600))

HEADER_B64=$(echo -n '{"alg":"RS256","typ":"JWT"}' | openssl base64 -e -A | tr '+/' '-_' | tr -d '=')
PAYLOAD_B64=$(echo -n "{\"iat\":${IAT},\"exp\":${EXP},\"iss\":\"${CLIENT_ID}\"}" | openssl base64 -e -A | tr '+/' '-_' | tr -d '=')
HEADER_PAYLOAD="${HEADER_B64}.${PAYLOAD_B64}"

SIGNATURE_B64=$(echo -n "${HEADER_PAYLOAD}" | openssl dgst -sha256 -sign "${KEY_FILE}" | openssl base64 -e -A | tr '+/' '-_' | tr -d '=')
JWT="${HEADER_PAYLOAD}.${SIGNATURE_B64}"

RESPONSE=$(curl -s -f -X POST \
  -H "Authorization: Bearer ${JWT}" \
  -H "Accept: application/vnd.github+json" \
  -H "User-Agent: Antigravity-Agent" \
  "https://api.github.com/app/installations/${INSTALLATION_ID}/access_tokens")

echo "${RESPONSE}" | grep -o '"token":"[^"]*"' | cut -d'"' -f4
