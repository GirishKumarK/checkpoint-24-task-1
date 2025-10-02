#!/usr/bin/env bash
set -euo pipefail

# Start roscore
roscore >/tmp/roscore.log 2>&1 &
ROSCORE_PID=$!
sleep 3

# Launch Gazebo + TortoiseBot world without GUI (adjust package/launch!)
# Common names are like: tortoisebot_gazebo/launch/tortoisebot_world.launch
# Or: tortoisebot_gazebo main.launch use_gui:=false
roslaunch tortoisebot_gazebo main.launch use_gui:=false >/tmp/gazebo.log 2>&1 &
GAZEBO_PID=$!

echo "Sim PIDs: roscore=$ROSCORE_PID gazebo=$GAZEBO_PID"
echo "Waiting for /gazebo node..."
timeout 60 bash -c 'until rosnode list | grep -q "/gazebo"; do sleep 1; done'
echo "Gazebo is up."

# Keep foreground if you want to observe; otherwise exit and let Jenkins tests run separately
wait
