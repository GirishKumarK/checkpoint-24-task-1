#!/usr/bin/env python3
import unittest
import math
import rospy
import rostest
import actionlib
from std_srvs.srv import Empty

from nav_msgs.msg import Odometry
from geometry_msgs.msg import Point, Twist
from tf import transformations
from tortoisebot_waypoints.msg import WaypointActionAction, WaypointActionGoal


class TestWaypoints(unittest.TestCase):
    def setUp(self):
        rospy.init_node('waypoints_test_node', anonymous=True)

        # Live state (filled by callback after setUp completes)
        self.pos = None
        self.yaw = 0.0
        rospy.Subscriber('/odom', Odometry, self._odom_cb)

        # Tolerances (overridable via ROS params)
        self.pos_tol = rospy.get_param('~pos_tol', 0.15)  # meters
        self.yaw_tol = rospy.get_param('~yaw_tol', 0.25)  # radians

        # Best-effort: unpause physics and nudge so odom starts promptly
        try:
            rospy.wait_for_service('/gazebo/unpause_physics', timeout=5.0)
            rospy.ServiceProxy('/gazebo/unpause_physics', Empty)()
        except Exception:
            pass
        rospy.Publisher('/cmd_vel', Twist, queue_size=1,
                        latch=True).publish(Twist())

        # Deterministically get one odom sample (no callback race)
        odom = rospy.wait_for_message('/odom', Odometry, timeout=30.0)
        p = odom.pose.pose.position
        q = odom.pose.pose.orientation
        self.init_pos = Point(p.x, p.y, p.z)
        self.init_yaw = transformations.euler_from_quaternion((q.x, q.y, q.z, q.w))[
            2]

        # Seed current state so later reads are non-None immediately
        self.pos = Point(self.init_pos.x, self.init_pos.y, self.init_pos.z)
        self.yaw = float(self.init_yaw)

        # Connect to action server
        self.client = actionlib.SimpleActionClient(
            'tortoisebot_as', WaypointActionAction)
        self.assertTrue(self.client.wait_for_server(rospy.Duration(20.0)),
                        "Action server not available")

    def _odom_cb(self, msg: Odometry):
        self.pos = msg.pose.pose.position
        q = msg.pose.pose.orientation
        self.yaw = transformations.euler_from_quaternion((q.x, q.y, q.z, q.w))[
            2]

    def _send_goal_and_wait(self, goal_point: Point):
        # Action type names come from 'WaypointAction.action' -> WaypointActionAction/Goal
        goal = WaypointActionGoal()
        goal.position = goal_point
        self.client.send_goal(goal)
        self.assertTrue(self.client.wait_for_result(rospy.Duration(60.0)),
                        "Action did not finish in time")
        rospy.sleep(1.0)  # let odom settle

    def test_position_and_yaw(self):
        # Target ~15 cm ahead of start
        target = Point(self.init_pos.x + 0.15, self.init_pos.y, 0.0)
        self._send_goal_and_wait(target)

        # Position error
        dx = (self.pos.x - target.x)
        dy = (self.pos.y - target.y)
        dist_err = math.hypot(dx, dy)
        self.assertLessEqual(dist_err, self.pos_tol,
                             "End position outside tolerance (%.3f m)" % dist_err)

        # Yaw should face the direction of travel
        desired_yaw = math.atan2(
            target.y - self.init_pos.y, target.x - self.init_pos.x)
        yaw_err = math.atan2(math.sin(self.yaw - desired_yaw),
                             math.cos(self.yaw - desired_yaw))
        self.assertLessEqual(abs(yaw_err), self.yaw_tol,
                             "End yaw outside tolerance (%.3f rad)" % abs(yaw_err))


if __name__ == '__main__':
    # Conventional test name (no .py)
    rostest.rosrun('tortoisebot_waypoints',
                   'waypoints_position_yaw_test.py', TestWaypoints)
