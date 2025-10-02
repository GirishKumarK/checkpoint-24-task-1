#!/usr/bin/env bash
set -e
source /opt/ros/noetic/setup.bash || true
if [ -f /root/simulation_ws/install/setup.bash ]; then
  source /root/simulation_ws/install/setup.bash
fi
exec "$@"
