#!/usr/bin/env bash
set -euo pipefail

: "${ROS_DOMAIN_ID:?ROS_DOMAIN_ID must be set on the host before starting Docker}"

xhost +local:docker

docker compose -f docker/docker-compose.yml run --rm sim bash
