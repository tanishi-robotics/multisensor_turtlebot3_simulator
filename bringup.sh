#!/bin/bash

usage() {
    echo "Usage: $(basename "$0") [--cpu|--gpu] [SESSION_NAME]"
    echo
    echo "  --cpu          Use CPU-only software rendering. This is the default."
    echo "  --gpu          Use the NVIDIA GPU Docker Compose override."
    echo "  SESSION_NAME   Optional. Name of the tmux session to create or attach."
    echo "                 If omitted, the default name 'tb3_simulator' will be used."
    echo
    echo "Examples:"
    echo "  $(basename "$0") --gpu mysession  # Create or attach to 'mysession' using GPU rendering"
    echo "  $(basename "$0") --cpu            # Create or attach to 'tb3_simulator' using CPU rendering"
}

use_gpu=0
session=tb3_simulator
session_set=0
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
script_dir_quoted="$(printf '%q' "$script_dir")"

while (($#)); do
  case "$1" in
    --cpu)
      use_gpu=0
      ;;
    --gpu)
      use_gpu=1
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    -*)
      echo "Unknown option: $1" >&2
      usage
      exit 1
      ;;
    *)
      if [ "$session_set" -eq 1 ]; then
        echo "Session name is already set: $session" >&2
        usage
        exit 1
      fi
      session="$1"
      session_set=1
      ;;
  esac
  shift
done

: "${ROS_DOMAIN_ID:?ROS_DOMAIN_ID must be set on the host before starting Docker}"

# sudo経由の実行を禁止（tmux関連の設定が反映されなくなるため）
if [ "$SUDO_USER" ]; then
    echo "エラー: このスクリプトはsudoで実行しないでください。" >&2
    echo "sudoなしで直接実行してください。" >&2
    exit 1
fi

# CycloneDDS向けのネットワークチューニングを可能な範囲で適用する。
# 権限がない環境では警告だけ出して、Docker/Gazeboの起動は継続する。
apply_sysctl() {
  local key="$1"
  local value="$2"

  if sysctl -w "${key}=${value}" >/dev/null 2>&1; then
    return 0
  fi

  if command -v sudo >/dev/null 2>&1 && sudo -n sysctl -w "${key}=${value}" >/dev/null 2>&1; then
    return 0
  fi

  echo "Warning: could not set ${key}; continuing without this network tuning." >&2
}

apply_sysctl net.core.rmem_max 2147483647
apply_sysctl net.ipv4.ipfrag_time 3
apply_sysctl net.ipv4.ipfrag_high_thresh 134217728

compose_files="-f docker/docker-compose.yml"
render_mode="CPU"

if [ "$use_gpu" -eq 1 ]; then
  compose_files="$compose_files -f docker/docker-compose.gpu.yml"
  render_mode="GPU"
fi

if tmux has-session -t "$session" 2>/dev/null; then
  echo "Session '$session' exists. Attaching..."
  tmux attach-session -t "$session"
  exit 0
fi

echo "Creating session '$session' with layout..."
tmux new-session -d -s "$session" -n main \
  \; split-window -h -l 80 \
  \; split-window -v -l 24 -t 0 \
  \; select-layout tiled

tmux send-keys -t "$session:0.0" "cd $script_dir_quoted" C-m
tmux send-keys -t "$session:0.0" '# Docker起動コマンド' C-m
tmux send-keys -t "$session:0.0" 'docker rm -f turtlebot3-sim-humble >/dev/null 2>&1 || true' C-m
tmux send-keys -t "$session:0.0" "docker compose $compose_files run -d --name turtlebot3-sim-humble sim sleep infinity" C-m
tmux send-keys -t "$session:0.0" "# Gazebo（$render_mode）起動コマンド" C-m
tmux send-keys -t "$session:0.0" 'docker exec -ti turtlebot3-sim-humble bash -lc "source /opt/ros/humble/setup.bash && source /ros2_ws/install/setup.bash && ros2 launch turtlebot3_stereo_sim turtlebot3_stereo_world.launch.py"' C-m

tmux send-keys -t "$session:0.1" 'sleep 3' C-m
tmux send-keys -t "$session:0.1" 'docker exec -ti turtlebot3-sim-humble bash' C-m
tmux send-keys -t "$session:0.1" 'source /opt/ros/humble/setup.bash' C-m
tmux send-keys -t "$session:0.1" 'source install/setup.bash' C-m
tmux send-keys -t "$session:0.1" 'ros2 launch turtlebot3_stereo_sim turtlebot3_stereo_rviz.launch.py' C-m

tmux send-keys -t "$session:0.2" 'sleep 3' C-m
tmux send-keys -t "$session:0.2" 'docker exec -ti turtlebot3-sim-humble bash' C-m
tmux send-keys -t "$session:0.2" 'source /opt/ros/humble/setup.bash' C-m
tmux send-keys -t "$session:0.2" 'source install/setup.bash' C-m

tmux attach-session -t "$session"
