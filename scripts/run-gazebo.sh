#!/usr/bin/env bash
set -euo pipefail

if command -v xhost >/dev/null 2>&1; then
  xhost +local:docker >/dev/null
fi

docker compose up sim
