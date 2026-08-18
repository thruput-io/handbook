#!/bin/sh
set -eu

agent_home="${HOME:?HOME is unset, cannot locate the API key for this account}"
api_key_file="${agent_home}/anthropic-api-key/api_key.txt"

exec cat "${api_key_file}"
