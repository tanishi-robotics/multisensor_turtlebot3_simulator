# TurtleBot3 Simulator on ROS 2 Humble

This workspace runs a ROS 2 Humble TurtleBot3 Waffle Gazebo simulation in Docker.
The default world is AWS RoboMaker Small House World from AWS Robotics, and the robot model includes an Intel RealSense R200 RGB/depth camera configuration.

## Requirements

- Docker
- Docker Compose v2
- tmux
- Linux desktop environment with X11
- `ROS_DOMAIN_ID` set on the host

See `requirement.txt` for the host-side dependency list.

## Quick Start

```bash
mkdir -p ~/repo
cd ~/repo
git clone https://github.com/<github-user-or-org>/turtlebot3_simulator.git
cd turtlebot3_simulator
export ROS_DOMAIN_ID=30
./scripts/build.sh
./bringup.sh --cpu
```

For NVIDIA GPU rendering, install NVIDIA Container Toolkit on the host and use:

```bash
export ROS_DOMAIN_ID=30
./bringup.sh --gpu
```

![Quick start demo](docs/assets/quick-start.gif)

The Docker container uses the exact `ROS_DOMAIN_ID` value provided by the host environment. The run scripts stop with an error if it is not set. The bringup flow keeps the Docker container alive after Gazebo is stopped with Ctrl-C. Stop the container explicitly with `docker stop turtlebot3-sim-humble` when it is no longer needed.

## Convenience Scripts

Use `bringup.sh` for normal startup. The scripts below are helper commands for launching Gazebo or RViz separately.

```bash
export ROS_DOMAIN_ID=30
./scripts/run-gazebo.sh --cpu
./scripts/run-rviz.sh --cpu
```

Use `--gpu` instead of `--cpu` when launching with NVIDIA GPU rendering.

## Published Interfaces

Expected ROS 2 topics published by the simulation:

- `/cmd_vel_safe`
- `/odom`
- `/scan`
- `/imu`
- `/joint_states`
- `/camera/image_raw`
- `/camera/camera_info`
- `/camera/depth/image_raw`
- `/camera/depth/camera_info`
- `/camera/depth/points`
- `/tf`
- `/tf_static`

Teleoperation commands should be published to `/cmd_vel`. The simulation relays `/cmd_vel` through a watchdog to `/cmd_vel_safe`, and the Gazebo diff drive plugin consumes `/cmd_vel_safe` so the robot stops if teleoperation commands disappear.

Camera TF frames are provided by the TurtleBot3 Waffle URDF:

- `base_link` -> `camera_link`
- `camera_link` -> `camera_rgb_frame`
- `camera_link` -> `camera_depth_frame`

## Directory Map

```text
.
|-- bringup.sh
|-- docker/
|   |-- Dockerfile
|   |-- Dockerfile.dockerignore
|   |-- docker-compose.gpu.yml
|   |-- docker-compose.yml
|   |-- cyclonedds.xml
|   `-- ros_entrypoint.sh
|-- docs/
|   `-- assets/
|       `-- quick-start.gif
|-- scripts/
|   |-- build.sh
|   |-- run-gazebo.sh
|   |-- run-rviz.sh
|   `-- shell.sh
|-- src/
|   `-- turtlebot3_stereo_sim/
|       |-- CMakeLists.txt
|       |-- package.xml
|       |-- launch/
|       |   |-- turtlebot3_stereo_rviz.launch.py
|       |   `-- turtlebot3_stereo_world.launch.py
|       |-- models/
|       |   `-- turtlebot3_waffle_stereo/
|       |       |-- model.config
|       |       `-- model.sdf
|       |-- rviz/
|       |   `-- turtlebot3_stereo.rviz
|       `-- scripts/
|           `-- cmd_vel_watchdog.py
|-- .gitignore
|-- LICENSE
|-- requirement.txt
`-- README.md
```

## License

This repository is licensed under the Apache License 2.0. See `LICENSE`.
Third-party software installed or downloaded by the Docker image, including ROS 2, TurtleBot3, Gazebo, CycloneDDS, and AWS RoboMaker Small House World, is distributed under each upstream project's license.
AWS RoboMaker Small House World is distributed under the MIT-0 license.

AWS RoboMaker Small House World is provided by AWS Robotics:
https://github.com/aws-robotics/aws-robomaker-small-house-world

---

# ROS 2 Humble TurtleBot3 Simulator

このワークスペースは、ROS 2 Humble の TurtleBot3 Waffle Gazebo simulation を Docker 上で起動します。
デフォルトの world は AWS Robotics の AWS RoboMaker Small House World です。
robot model には Intel RealSense R200 RGB/depth camera 構成を含めています。
ROS middleware implementation には CycloneDDS を使います。

## 必要環境

- Docker
- Docker Compose v2
- tmux
- X11 が使える Linux desktop environment
- host 側で `ROS_DOMAIN_ID` が設定されていること

host 側の依存関係一覧は `requirement.txt` を参照してください。

## クイックスタート

```bash
mkdir -p ~/repo
cd ~/repo
git clone https://github.com/<github-user-or-org>/turtlebot3_simulator.git
cd turtlebot3_simulator
export ROS_DOMAIN_ID=30
./scripts/build.sh
./bringup.sh --cpu
```

NVIDIA GPU rendering を使う場合は、host に NVIDIA Container Toolkit を入れたうえで次を実行します。

```bash
export ROS_DOMAIN_ID=30
./bringup.sh --gpu
```

![Quick start demo](docs/assets/quick-start.gif)

Docker container 内の `ROS_DOMAIN_ID` は、host 環境変数の値に固定されます。未設定の場合、起動スクリプトはエラーで停止します。
bringup 経由では Gazebo を Ctrl-C で停止しても Docker container は起動したまま残ります。不要になったら `docker stop turtlebot3-sim-humble` で明示的に停止してください。

## 便利スクリプト

通常の起動には `bringup.sh` を使ってください。以下の scripts は Gazebo または RViz を個別に起動したい場合の補助コマンドです。

```bash
export ROS_DOMAIN_ID=30
./scripts/run-gazebo.sh --cpu
./scripts/run-rviz.sh --cpu
```

NVIDIA GPU rendering で起動する場合は `--cpu` の代わりに `--gpu` を指定してください。

## 公開インターフェース

simulation が publish する ROS 2 topics:

- `/cmd_vel_safe`
- `/odom`
- `/scan`
- `/imu`
- `/joint_states`
- `/camera/image_raw`
- `/camera/camera_info`
- `/camera/depth/image_raw`
- `/camera/depth/camera_info`
- `/camera/depth/points`
- `/tf`
- `/tf_static`

teleop の速度指令は `/cmd_vel` に publish してください。simulation は `/cmd_vel` を watchdog 経由で `/cmd_vel_safe` へ relay し、Gazebo の diff drive plugin は `/cmd_vel_safe` を使います。これにより teleop の指令が途切れた場合も robot が停止します。

camera TF frames は TurtleBot3 Waffle URDF から publish されます。

- `base_link` -> `camera_link`
- `camera_link` -> `camera_rgb_frame`
- `camera_link` -> `camera_depth_frame`

## ディレクトリマップ

```text
.
|-- bringup.sh
|-- docker/
|   |-- Dockerfile
|   |-- Dockerfile.dockerignore
|   |-- docker-compose.gpu.yml
|   |-- docker-compose.yml
|   |-- cyclonedds.xml
|   `-- ros_entrypoint.sh
|-- docs/
|   `-- assets/
|       `-- quick-start.gif
|-- scripts/
|   |-- build.sh
|   |-- run-gazebo.sh
|   |-- run-rviz.sh
|   `-- shell.sh
|-- src/
|   `-- turtlebot3_stereo_sim/
|       |-- CMakeLists.txt
|       |-- package.xml
|       |-- launch/
|       |   |-- turtlebot3_stereo_rviz.launch.py
|       |   `-- turtlebot3_stereo_world.launch.py
|       |-- models/
|       |   `-- turtlebot3_waffle_stereo/
|       |       |-- model.config
|       |       `-- model.sdf
|       |-- rviz/
|       |   `-- turtlebot3_stereo.rviz
|       `-- scripts/
|           `-- cmd_vel_watchdog.py
|-- .gitignore
|-- LICENSE
|-- requirement.txt
`-- README.md
```

## ライセンス

このリポジトリのライセンス詳細は `LICENSE` を参照してください。
Docker image 内で install または download される ROS 2、TurtleBot3、Gazebo、CycloneDDS、AWS RoboMaker Small House World などの third-party software は、それぞれの upstream project の license に従います。
AWS RoboMaker Small House World は MIT-0 license で配布されています。

AWS RoboMaker Small House World は AWS Robotics により提供されています:
https://github.com/aws-robotics/aws-robomaker-small-house-world
