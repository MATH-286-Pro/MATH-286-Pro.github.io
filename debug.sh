#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"

PORT="${1:-4000}"
HOST="${HOST:-127.0.0.1}"
MAX_TRIES="${MAX_TRIES:-20}"

if ! command -v bundle >/dev/null 2>&1; then
  echo "Error: bundler not found. Please install Ruby + bundler first."
  echo "Try: sudo apt install ruby-dev ruby-bundler nodejs"
  exit 1
fi

port_in_use() {
  local port="$1"
  if command -v ss >/dev/null 2>&1; then
    ss -ltn "sport = :${port}" | tail -n +2 | grep -q .
    return $?
  fi

  if command -v lsof >/dev/null 2>&1; then
    lsof -iTCP:"${port}" -sTCP:LISTEN -t >/dev/null 2>&1
    return $?
  fi

  return 1
}

original_port="${PORT}"
tries=0
while port_in_use "${PORT}" && [ "${tries}" -lt "${MAX_TRIES}" ]; do
  PORT=$((PORT + 1))
  tries=$((tries + 1))
done

if [ "${tries}" -ge "${MAX_TRIES}" ] && port_in_use "${PORT}"; then
  echo "Error: no free port found in range ${original_port}..$((original_port + MAX_TRIES))"
  exit 1
fi

if [ "${PORT}" != "${original_port}" ]; then
  echo "Port ${original_port} is busy, switched to ${PORT}"
fi

echo "Starting Jekyll preview at http://${HOST}:${PORT}"
exec bundle exec jekyll serve -H "${HOST}" -P "${PORT}"
