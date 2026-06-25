import os

from ament_index_python.packages import get_package_share_directory
from launch import LaunchDescription
from launch.actions import DeclareLaunchArgument, IncludeLaunchDescription
from launch.conditions import IfCondition
from launch.launch_description_sources import PythonLaunchDescriptionSource
from launch.substitutions import LaunchConfiguration
from launch_ros.actions import Node


def generate_launch_description():
    pkg_gazebo_ros = get_package_share_directory('gazebo_ros')
    pkg_stereo_sim = get_package_share_directory('turtlebot3_stereo_sim')
    pkg_turtlebot3_gazebo = get_package_share_directory('turtlebot3_gazebo')
    small_house_world_path = os.environ.get(
        'SMALL_HOUSE_WORLD_PATH',
        '/opt/aws-robomaker-small-house-world',
    )
    turtlebot3_model = os.environ.get('TURTLEBOT3_MODEL', 'waffle')

    use_sim_time = LaunchConfiguration('use_sim_time', default='true')
    gui = LaunchConfiguration('gui', default='true')
    x_pose = LaunchConfiguration('x_pose', default='-3.5')
    y_pose = LaunchConfiguration('y_pose', default='-4.5')
    yaw_pose = LaunchConfiguration('yaw_pose', default='1.58')

    world = os.path.join(
        small_house_world_path,
        'worlds',
        'small_house.world',
    )

    model = os.path.join(
        pkg_stereo_sim,
        'models',
        'turtlebot3_waffle_stereo',
        'model.sdf',
    )

    urdf_path = os.path.join(
        pkg_turtlebot3_gazebo,
        'urdf',
        f'turtlebot3_{turtlebot3_model}.urdf',
    )

    with open(urdf_path, 'r') as urdf_file:
        robot_description = urdf_file.read()

    gzserver_cmd = IncludeLaunchDescription(
        PythonLaunchDescriptionSource(
            os.path.join(pkg_gazebo_ros, 'launch', 'gzserver.launch.py')
        ),
        launch_arguments={'world': world}.items(),
    )

    gzclient_cmd = IncludeLaunchDescription(
        PythonLaunchDescriptionSource(
            os.path.join(pkg_gazebo_ros, 'launch', 'gzclient.launch.py')
        ),
        condition=IfCondition(gui),
    )

    robot_state_publisher_cmd = Node(
        package='robot_state_publisher',
        executable='robot_state_publisher',
        name='robot_state_publisher',
        output='screen',
        parameters=[{
            'use_sim_time': use_sim_time,
            'robot_description': robot_description,
        }],
    )

    spawn_turtlebot_cmd = Node(
        package='gazebo_ros',
        executable='spawn_entity.py',
        arguments=[
            '-entity', 'waffle',
            '-file', model,
            '-x', x_pose,
            '-y', y_pose,
            '-z', '0.01',
            '-Y', yaw_pose,
        ],
        output='screen',
    )

    cmd_vel_watchdog_cmd = Node(
        package='turtlebot3_stereo_sim',
        executable='cmd_vel_watchdog.py',
        name='cmd_vel_watchdog',
        output='screen',
        parameters=[{
            'input_topic': 'cmd_vel',
            'output_topic': 'cmd_vel_safe',
            'timeout_sec': 0.3,
            'publish_rate_hz': 20.0,
        }],
    )

    ld = LaunchDescription()
    ld.add_action(DeclareLaunchArgument(
        'gui',
        default_value='true',
        description='Start Gazebo GUI client when true.',
    ))
    ld.add_action(gzserver_cmd)
    ld.add_action(gzclient_cmd)
    ld.add_action(robot_state_publisher_cmd)
    ld.add_action(spawn_turtlebot_cmd)
    ld.add_action(cmd_vel_watchdog_cmd)

    return ld
