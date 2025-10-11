# TortoiseBot Waypoints (ROS1)

Action server and rostests for sending a waypoint and verifying the robot reaches it
(final **position** and **yaw**) in Gazebo.

## How to Run the Integration Test

### Terminal 1 – Start Gazebo Simulation
source /opt/ros/noetic/setup.bash
source ~/simulation_ws/devel/setup.bash
roslaunch tortoisebot_gazebo tortoisebot_playground.launch

### Terminal 2 – Launch the Waypoints Action Server
source /opt/ros/noetic/setup.bash
cd ~/simulation_ws && catkin_make && source devel/setup.bash
rosrun tortoisebot_waypoints tortoisebot_action_server.py

### Terminal 3 – Run the Tests
source /opt/ros/noetic/setup.bash
cd ~/simulation_ws && catkin_make && source devel/setup.bash
rostest tortoisebot_waypoints waypoints_test.test --reuse-master

### Passing vs Failing Conditions
Inside the test file
~/simulation_ws/src/tortoisebot_waypoints/tests/waypoints_position_yaw_test.py
the target waypoint is defined like this:
# Example passing condition
target = Point(self.init_pos.x + 0.15, self.init_pos.y, 0.0)

With this small forward move, the robot successfully reaches the goal.
Expected output:
[ROSTEST]-----------------------------------------------------------------------
SUMMARY
 * RESULT: SUCCESS
 * TESTS: 1
 * ERRORS: 0
 * FAILURES: 0


# Example failing condition
target = Point(self.init_pos.x + 1.0, self.init_pos.y, 0.0)
[ROSTEST]-----------------------------------------------------------------------
SUMMARY
 * RESULT: FAIL
 * TESTS: 1
 * ERRORS: 0
 * FAILURES: 1