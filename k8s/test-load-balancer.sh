#!/usr/bin/env bash

# Sends fresh HTTP connections to a service and summarizes returned backends.
set -euo pipefail

url="${1:-http://localhost:8080}"
request_count="${2:-1000}"
results_file="$(mktemp)"

cleanup() {
  rm -f "$results_file"
}
trap cleanup EXIT

if ! [[ "$request_count" =~ ^[1-9][0-9]*$ ]]; then
  echo "Request count must be a positive integer; received: $request_count" >&2
  exit 2
fi

echo "Sending $request_count requests to $url"

for ((request_number = 1; request_number <= request_count; request_number++)); do
  # HTTP/1.0 and Connection: close ensure curl opens a new TCP connection per request.
  if response="$(curl --silent --show-error --fail --http1.0 --no-keepalive \
    --connect-timeout 2 --max-time 5 "$url")"; then
    printf '%s\n' "$response" >> "$results_file"
  else
    printf '%s\n' '<request failed>' >> "$results_file"
  fi
done

echo
echo "Response distribution:"
sort "$results_file" | uniq -c | sort -rn
