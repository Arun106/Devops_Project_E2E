#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <vm-public-ip-or-host> [port]" >&2
  exit 2
fi

HOST="$1"
PORT="${2:-8080}"
URL="http://${HOST}:${PORT}/devops-e2e-app/hello"

BODY="$(curl -fsS --max-time 15 "$URL")"
if [[ "$BODY" == *"SUCCESS"* ]]; then
  echo "SUCCESS: $URL"
else
  echo "FAILED: unexpected response from $URL" >&2
  echo "$BODY" >&2
  exit 1
fi
