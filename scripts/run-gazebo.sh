#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage: ./scripts/run-gazebo.sh [--gui|--headless]

Options:
  --gui    Start Gazebo with gzclient. This is the default.
  --headless
           Start only gzserver without the Gazebo GUI client.
  -h, --help
           Show this help.
USAGE
}

use_gui=true

while (($#)); do
  case "$1" in
    --gui)
      use_gui=true
      ;;
    --headless)
      use_gui=false
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
  shift
done

: "${ROS_DOMAIN_ID:?ROS_DOMAIN_ID must be set on the host before starting Docker}"

xhost +local:docker

container_name=turtlebot3-sim-humble
gui_name=GUI

if [ "$use_gui" = false ]; then
  gui_name=headless
fi

container_is_running() {
  docker ps --format '{{.Names}}' | grep -qx "$container_name"
}

if ! container_is_running; then
  docker rm -f "$container_name" >/dev/null 2>&1 || true
  docker compose -f docker/docker-compose.yml \
    run -d --name "$container_name" sim sleep infinity
fi

echo "Starting Gazebo in $gui_name mode. Press Ctrl-C to stop Gazebo; the Docker container will keep running."

docker exec -ti "$container_name" bash -lc \
  "source /opt/ros/humble/setup.bash && source /ros2_ws/install/setup.bash && ros2 launch turtlebot3_stereo_sim turtlebot3_stereo_world.launch.py gui:=$use_gui"
