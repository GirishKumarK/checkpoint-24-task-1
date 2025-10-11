# scripts/entrypoint_ci.sh
#!/usr/bin/env bash
set -euo pipefail
source /opt/ros/noetic/setup.bash
source /root/simulation_ws/install/setup.bash

# Start sim in background (roscore + gazebo + spawn)
bash /run_sim.sh &

# Wait for ROS master and /odom
echo "Waiting for ROS master..."
for i in {1..30}; do rostopic list >/dev/null 2>&1 && break; sleep 1; done
echo "Waiting for /odom..."
for i in {1..30}; do rostopic list | grep -qE '^/odom$' && break; sleep 1; done

# Run tests (will exit non-zero on failure)
bash /test_waypoints.sh
