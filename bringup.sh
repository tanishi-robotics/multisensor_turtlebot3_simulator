#!/bin/bash

usage() {
    echo "Usage: $(basename "$0") [SESSION_NAME]"
    echo
    echo "  SESSION_NAME   Optional. Name of the tmux session to create or attach."
    echo "                 If omitted, the default name 'default' will be used."
    echo
    echo "Examples:"
    echo "  $(basename "$0") mysession    # Create or attach to 'mysession'"
    echo "  $(basename "$0")              # Create or attach to 'tb3_simulator'"
    exit 1
}

if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    usage
fi

# sudo経由の実行を禁止（tmux関連の設定が反映されなくなるため）
if [ "$SUDO_USER" ]; then
    echo "エラー: このスクリプトはsudoで実行しないでください。" >&2
    echo "sudoなしで直接実行してください。" >&2
    exit 1
fi

# cyclonddsと併せてネットワークチューニングを実施
sudo sysctl -w net.core.rmem_max=2147483647  # 2 GiB, default is 208 KiB
sudo sysctl -w net.ipv4.ipfrag_time=3  # in seconds, default is 30 s
sudo sysctl -w net.ipv4.ipfrag_high_thresh=134217728  # 128 MiB, default is 256 KiB

session=${1:-tb3_simulator}

# セッション存在確認
if tmux has-session -t "$session" 2>/dev/null; then
  echo "Session '$session' exists. Attaching..."
else
  echo "Creating session '$session' with layout..."
  tmux new-session -d -s "$session" -n main \
    \; split-window -h -l 80 \
    \; split-window -v -l 24 -t 0 \
    \; select-layout tiled
fi

tmux send-keys -t 0 'cd ~/repo/turtlebot3_simulator && bash ./scripts/run-gazebo-gpu.sh' C-m

tmux send-keys -t 1 'sleep 3' C-m
tmux send-keys -t 1 'docker exec -ti turtlebot3-sim-humble bash' C-m
tmux send-keys -t 1 'source /opt/ros/humble/setup.bash' C-m
tmux send-keys -t 1 'source install/setup.bash' C-m
tmux send-keys -t 1 'ros2 launch turtlebot3_stereo_sim turtlebot3_stereo_rviz.launch.py' C-m

tmux send-keys -t 2 'sleep 3' C-m
tmux send-keys -t 2 'docker exec -ti turtlebot3-sim-humble bash' C-m
tmux send-keys -t 2 'source /opt/ros/humble/setup.bash' C-m
tmux send-keys -t 2 'source install/setup.bash' C-m

tmux attach-session -t "$session"
