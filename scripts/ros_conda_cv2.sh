#!/usr/bin/env bash

conda install -c conda-forge rospkg catkin_pkg opencv

conda install -c conda-forge ros-rosbag ros-sensor-msgs

pip install opencv-python

#mv /opt/ros/kinetic/lib/python2.7/dist-packages/cv2.so /opt/ros/kinetic/lib/python2.7/dist-packages/cv2_ros.so

mkdir /root/catkin_build_ws

cd /root/catkin_build_ws

catkin config -DPYTHON_EXECUTABLE=/opt/conda/bin/python -DPYTHON_INCLUDE_DIR=/opt/conda/include/python3.6m -DPYTHON_LIBRARY=/opt/conda/lib/libpython3.6m.so

catkin config --install

mkdir src && cd src

git clone -b kinetic https://github.com/ros-perception/vision_opencv.git

cd /root/catkin_build_ws

catkin_make_isolated --install -DCMAKE_BUILD_TYPE=Release -DSETUPTOOLS_DEB_LAYOUT=OFF
