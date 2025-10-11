#!/usr/bin/env bash
#set -euo pipefail

# --- Env ---
source /opt/ros/noetic/setup.bash
[ -f /root/simulation_ws/install/setup.bash ] && source /root/simulation_ws/install/setup.bash || true
[ -f /root/simulation_ws/devel/setup.bash ]   && source /root/simulation_ws/devel/setup.bash   || true

echo "ROS_MASTER_URI=$ROS_MASTER_URI"
echo "ROS_HOSTNAME=$ROS_HOSTNAME"

# If no DISPLAY, start a virtual X (lets this work headless too)
if [[ -z "${DISPLAY:-}" ]]; then
  export DISPLAY=:99
  Xvfb :99 -screen 0 1280x800x24 &
  sleep 1
fi

# Launch the sim (GUI if DISPLAY is real; headless if Xvfb)
#exec roslaunch tortoisebot_gazebo tortoisebot_playground.launch

SIM_PID=""

# --- Wait for existing Gazebo (from compose 'sim'), else launch headless locally ---
echo "Waiting for /gazebo node (up to 10s)..."
if ! timeout 10 bash -lc 'until rosnode list 2>/dev/null | grep -q "/gazebo"; do sleep 1; done'; then
  echo "No external gazebo found; launching headless sim locally..."
  roslaunch tortoisebot_gazebo tortoisebot_playground.launch gui:=false >/tmp/gazebo_tests.log 2>&1 &
  SIM_PID=$!
  echo "Waiting for /gazebo node from local launch..."
  timeout 120 bash -lc 'until rosnode list 2>/dev/null | grep -q "/gazebo"; do sleep 1; done'
fi
echo "Gazebo is up."

# --- Gate on /odom publisher and a real message ---
#echo "[gate] waiting for /odom publisher (60s max)…"
#if ! timeout 60 bash -lc '
#  until rostopic info /odom 2>/dev/null | awk "/^Publishers:/{p=1;next} /^Subscribers:/{p=0} p && NF{exit 0} END{exit 1}";
#  do sleep 1; done'; then
#  echo "[gate] ERROR: /odom has no publisher; aborting."
#  exit 2
#fi

#echo "[gate] ensuring at least one /odom message (30s max)…"
#if ! rostopic echo -n1 /odom >/dev/null 2>&1; then
#  echo "[gate] ERROR: no /odom message observed;not aborting."
  #exit 2
#fi

echo "[debug] current topics:"
rostopic list

# --- Start the Waypoints Action Server ---
#echo "[server] starting tortoisebot_action_server.py ..."
#rosrun tortoisebot_waypoints tortoisebot_action_server.py &
#SERVER_PID=$!

# Wait for action topics to appear
#echo "[server] waiting for action topics (/tortoisebot_as/*) (30s max)..."
#if ! timeout 30 bash -lc 'until rostopic list | grep -q "^/tortoisebot_as/goal$"; do sleep 1; done'; then
#  echo "[server] ERROR: action topics not found; server may not have started."
#  ps -o pid,cmd -p "$SERVER_PID" || true
#  kill "$SERVER_PID" >/dev/null 2>&1 || true
  #exit 3
#fi
#echo "[server] action server is up."

# --- Run the client (your test script as a standalone client) ---
# This script sends a goal and asserts on position/yaw.
#echo "[client] running waypoints_position_yaw_test.py ..."
#rosrun tortoisebot_waypoints waypoints_position_yaw_test.py
#CLIENT_RC=$?
#echo "[client] exit code: $CLIENT_RC"

rostest tortoisebot_waypoints test_waypoints_action.test --reuse-master


# --- Keep the container alive ---
#if [[ -n "${SIM_PID:-}" ]]; then
#  echo "Local Gazebo running (pid $SIM_PID); keeping container alive (waiting on it)…"
#  wait "$SIM_PID"
#else
#  echo "External Gazebo detected; keeping container alive."
#  tail -f /dev/null
#fi

# --- Cleanup ---
#rosnode kill -a >/dev/null 2>&1 || true
#[[ -n "${SIM_PID:-}" ]] && kill "$SIM_PID" >/dev/null 2>&1 || true
#[[ -n "${XVFB_PID:-}" ]] && kill "$XVFB_PID" >/dev/null 2>&1 || true

#exit $RC
