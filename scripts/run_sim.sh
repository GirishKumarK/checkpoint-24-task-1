#!/usr/bin/env bash
set -euo pipefail

# Source ROS + workspace
source /opt/ros/noetic/setup.bash
[ -f /root/simulation_ws/install/setup.bash ] && source /root/simulation_ws/install/setup.bash || true
[ -f /root/simulation_ws/devel/setup.bash ]   && source /root/simulation_ws/devel/setup.bash   || true

# If no DISPLAY, start a virtual X (lets this work headless too)
if [[ -z "${DISPLAY:-}" ]]; then
  export DISPLAY=:99
  Xvfb :99 -screen 0 1280x800x24 &
  sleep 1
fi

# Launch the sim (GUI if DISPLAY is real; headless if Xvfb)
exec roslaunch tortoisebot_gazebo tortoisebot_playground.launch