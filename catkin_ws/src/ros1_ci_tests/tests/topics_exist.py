#!/usr/bin/env python
import rospy
import unittest
import rostopic
import time


class TestTopics(unittest.TestCase):
    def wait_topic(self, name, timeout=60):
        start = time.time()
        while time.time() - start < timeout:
            pubs, _ = rostopic.get_topic_list()
            if any(t[0] == name for t in pubs):
                return True
            rospy.sleep(1.0)
        return False

    def test_gazebo_topics_present(self):
        self.assertTrue(self.wait_topic('/gazebo/link_states', 60))

    def test_laser_topic_present(self):
        self.assertTrue(self.wait_topic('/scan', 60)
                        or self.wait_topic('/laser/scan', 60))


if __name__ == '__main__':
    import rostest
    rospy.init_node('ros1_ci_topics_test', anonymous=True)
    rostest.rosrun('ros1_ci_tests', 'topics_exist', TestTopics)
