# ROS Noetic + Gazebo headless base
FROM ros:noetic-desktop-full

SHELL ["/bin/bash", "-lc"]

# Noninteractive apt & locale
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update -y && apt-get install -y --no-install-recommends \
    git curl ca-certificates \
    python3-pip python3-rosdep python3-catkin-tools \
    ros-noetic-gazebo-ros ros-noetic-gazebo-plugins ros-noetic-gazebo-ros-control \
    ros-noetic-ros-controllers ros-noetic-controller-manager \
    ros-noetic-joint-state-publisher ros-noetic-robot-state-publisher \
    xvfb x11-apps \
    && rm -rf /var/lib/apt/lists/*

# Initialize rosdep
RUN rosdep init || true
RUN rosdep update

# Workspace
ENV CATKIN_WS=/root/simulation_ws
RUN mkdir -p $CATKIN_WS/src
WORKDIR $CATKIN_WS

# ------------------------------
# Bring in your code
# ------------------------------
# Option A (recommended): copy src contents from repo into the image
# Make sure you copy your tortoisebot_waypoints and the TortoiseBot sim packages into ./src before building.
COPY src/ $CATKIN_WS/src/

# Option B (alternative): clone sim packages here via ARGs (uncomment & set your URLs)
# ARG TORTOISEBOT_SIM_URL=https://github.com/yourorg/tortoisebot_sim_ros1.git
# RUN git clone --depth 1 "$TORTOISEBOT_SIM_URL" $CATKIN_WS/src/tortoisebot_sim_ros1

# Install package dependencies
RUN rosdep install --from-paths src --ignore-src -r -y

# Build catkin
RUN source /opt/ros/noetic/setup.bash && catkin config --extend /opt/ros/noetic --install && catkin build

# Runtime environment
ENV ROS_DISTRO=noetic
ENV ROS_VERSION=1
ENV ROS_PACKAGE_PATH=$CATKIN_WS/src:$ROS_PACKAGE_PATH
ENV GAZEBO_MODEL_PATH=$CATKIN_WS/src:$GAZEBO_MODEL_PATH
ENV GAZEBO_RESOURCE_PATH=$CATKIN_WS/src:$GAZEBO_RESOURCE_PATH

# Default ROS master
ENV ROS_MASTER_URI=http://localhost:11311
ENV ROS_HOSTNAME=localhost

# Entrypoint to source workspace and keep env
COPY scripts/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Helper scripts (launch + tests)
COPY scripts/run_sim.sh /run_sim.sh
COPY scripts/test_waypoints.sh /test_waypoints.sh
RUN chmod +x /run_sim.sh /test_waypoints.sh

ENTRYPOINT ["/entrypoint.sh"]
CMD ["bash"]
