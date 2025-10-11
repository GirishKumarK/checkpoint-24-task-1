# ROS Noetic + Gazebo headless base
FROM osrf/ros:noetic-desktop-full

SHELL ["/bin/bash", "-lc"]
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update -y && apt-get install -y --no-install-recommends \
    git curl ca-certificates \
    python3-pip python3-rosdep python3-catkin-tools \
    ros-noetic-gazebo-ros ros-noetic-gazebo-plugins ros-noetic-gazebo-ros-control \
    ros-noetic-ros-controllers ros-noetic-controller-manager \
    ros-noetic-joint-state-publisher ros-noetic-robot-state-publisher \
    xvfb x11-apps \
    && rm -rf /var/lib/apt/lists/*

# rosdep
RUN rosdep init || true
RUN rosdep update

# Workspace
ENV CATKIN_WS=/root/simulation_ws
RUN mkdir -p $CATKIN_WS/src
WORKDIR $CATKIN_WS

# ------------------------------
# Bring in code (paths are from the WORKSPACE ROOT build context)
# ------------------------------
# TortoiseBot packages living under simulation_ws/src/
COPY ./tortoisebot               $CATKIN_WS/src/tortoisebot

# Your ROS1 CI packages under simulation_ws/src/ros1_ci/catkin_ws/src/
#COPY src/ros1_ci/catkin_ws/src/tortoisebot_waypoints $CATKIN_WS/src/tortoisebot_waypoints
#COPY src/ros1_ci/catkin_ws/src/ros1_ci_tests         $CATKIN_WS/src/ros1_ci_tests

# Scripts under simulation_ws/src/ros1_ci/scripts/
COPY ./scripts/entrypoint.sh     /entrypoint.sh
COPY ./scripts/run_sim.sh        /run_sim.sh
COPY ./scripts/test_waypoints.sh /test_waypoints.sh
RUN chmod +x /entrypoint.sh /run_sim.sh /test_waypoints.sh

# Install deps and build
RUN rosdep install --from-paths src --ignore-src -r -y
RUN source /opt/ros/noetic/setup.bash && catkin config --extend /opt/ros/noetic --install && catkin build

# Runtime env
ENV ROS_DISTRO=noetic
ENV ROS_VERSION=1
ENV ROS_PACKAGE_PATH=$CATKIN_WS/src:$ROS_PACKAGE_PATH
ENV GAZEBO_MODEL_PATH=$CATKIN_WS/src:$GAZEBO_MODEL_PATH
ENV GAZEBO_RESOURCE_PATH=$CATKIN_WS/src:$GAZEBO_RESOURCE_PATH
#ENV ROS_MASTER_URI=http://localhost:11311
#ENV ROS_HOSTNAME=localhost

ENTRYPOINT ["/entrypoint.sh"]
CMD ["bash"]
