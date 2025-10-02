#!/usr/bin/env bash
set -euo pipefail

# ROS env
source /opt/ros/noetic/setup.bash
source /ws/devel/setup.bash

# Virtual display for Gazebo
Xvfb :99 -screen 0 1280x1024x24 >/tmp/xvfb.log 2>&1 &
XVFB_PID=$!
export DISPLAY=:99

cleanup() {
  # Try to stop launch and the virtual display cleanly
  rosnode kill -a >/dev/null 2>&1 || true
  kill $GAZEBO_PID >/dev/null 2>&1 || true
  kill $XVFB_PID  >/dev/null 2>&1 || true
}
trap cleanup EXIT

# Launch the world (headless)
roslaunch tortoisebot_gazebo tortoisebot_playground.launch gui:=false pause:=false &
GAZEBO_PID=$!

# Give Gazebo time to come up
sleep 20

# Run your ROS1 tests (adjust if your test file/package name is different)
rostest ros1_ci_tests waypoints.test --text
echo "[CI] Tests finished successfully."
