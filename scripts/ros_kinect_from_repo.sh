#!/usr/bin/env bash

set -e

apt install -y lsb-release

sh -c 'echo "deb http://packages.ros.org/ros/ubuntu $(lsb_release -sc) main" > /etc/apt/sources.list.d/ros-latest.list'

apt-key adv --keyserver 'hkp://keyserver.ubuntu.com:80' --recv-key C1CF6E31E6BADE8868B172B4F42ED6FBAB17C654 || curl -sSL 'http://keyserver.ubuntu.com/pks/lookup?op=get&search=0xC1CF6E31E6BADE8868B172B4F42ED6FBAB17C654' | apt-key add -

apt-get update

apt-get install -y ros-kinetic-ros-base python-rosdep python-rosinstall python-rosinstall-generator python-wstool build-essential python-opencv ros-kinetic-cv-bridge

echo "source /opt/ros/kinetic/setup.bash" >> ~/.bashrc
source ~/.bashrc

rosdep init
rosdep update

echo "ROS installed successfully!"
