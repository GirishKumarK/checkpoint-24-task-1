#!/usr/bin/env bash
set -euo pipefail

# Source the workspace
source /opt/ros/noetic/setup.bash || true
[ -f /root/simulation_ws/install/setup.bash ] && source /root/simulation_ws/install/setup.bash || true

# Single command: launch the test which itself starts headless Gazebo and the node(s)
# Make sure your tortoisebot_waypoints/test/waypoints_action.test includes the headless sim include
rostest tortoisebot_waypoints waypoints_action.test
