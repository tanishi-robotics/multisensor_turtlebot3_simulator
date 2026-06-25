#!/usr/bin/env python3

import time

import rclpy
from geometry_msgs.msg import Twist
from rclpy.node import Node


class CmdVelWatchdog(Node):
    def __init__(self):
        super().__init__('cmd_vel_watchdog')

        self.declare_parameter('input_topic', 'cmd_vel')
        self.declare_parameter('output_topic', 'cmd_vel_safe')
        self.declare_parameter('timeout_sec', 0.3)
        self.declare_parameter('publish_rate_hz', 20.0)

        input_topic = self.get_parameter('input_topic').value
        output_topic = self.get_parameter('output_topic').value
        self.timeout_sec = float(self.get_parameter('timeout_sec').value)
        publish_rate_hz = float(self.get_parameter('publish_rate_hz').value)

        self.last_msg = Twist()
        self.last_msg_time = 0.0

        self.publisher = self.create_publisher(Twist, output_topic, 10)
        self.subscription = self.create_subscription(
            Twist,
            input_topic,
            self.cmd_vel_callback,
            10,
        )

        # Gazebo の diff drive plugin が最後の速度指令を保持するため、
        # 入力が途切れたらゼロ速度を継続 publish して安全に停止させる。
        self.timer = self.create_timer(1.0 / publish_rate_hz, self.timer_callback)

        self.get_logger().info(
            f'Forwarding /{input_topic} to /{output_topic} with '
            f'{self.timeout_sec:.2f}s timeout'
        )

    def cmd_vel_callback(self, msg):
        self.last_msg = msg
        self.last_msg_time = time.monotonic()

    def timer_callback(self):
        now = time.monotonic()
        if self.last_msg_time > 0.0 and now - self.last_msg_time <= self.timeout_sec:
            self.publisher.publish(self.last_msg)
            return

        self.publisher.publish(Twist())


def main(args=None):
    rclpy.init(args=args)
    node = CmdVelWatchdog()
    try:
        rclpy.spin(node)
    except KeyboardInterrupt:
        pass
    finally:
        node.destroy_node()
        if rclpy.ok():
            rclpy.shutdown()


if __name__ == '__main__':
    main()
