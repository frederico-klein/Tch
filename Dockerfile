FROM pytorch/pytorch:1.3-cuda10.1-cudnn7-runtime

WORKDIR /workspace
RUN chmod -R a+w /workspace


############# needs sshd 

ENV DEBIAN_FRONTEND noninteractive

RUN apt-get -y update
RUN apt-get install -y --fix-missing \
  python3-pip \
  python-pip \
  openssh-server\
  libssl-dev \
  tar\
  libboost-all-dev \
  && apt-get clean && rm -rf /tmp/* /var/tmp/*

# to get ssh working for the ros machine to be functional: (adapted from docker docs running_ssh_service)
RUN mkdir /var/run/sshd \
    && echo 'root:ros_ros' | chpasswd \
    && sed -i 's/PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config \
    && sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd

ENV NOTVISIBLE "in users profile"
RUN echo "export VISIBLE=now" >> /etc/profile

EXPOSE 22

###
# we want torch vision v0.4.1 to be compatible with torch 1.3
RUN git clone https://github.com/pytorch/vision.git && cd vision && git checkout v0.4.1 && pip install -v .

#add my snazzy banner
ADD banner.txt /root/

#ADD scripts/ros_kinect_from_repo.sh /root/
#ADD scripts/ros.sh /root/
#ADD requirements_ros.txt /root/
#ENV TERM xterm-256color
ADD scripts/ros_conda_cv2.sh /root/
RUN /root/ros_conda_cv2.sh

#RUN /root/ros.sh
#RUN /root/ros_kinect_from_repo.sh && rm /root/ros_kinect_from_repo.sh

ADD scripts/entrypoint.sh /root/
ENTRYPOINT ["/root/entrypoint.sh"]
###needs the catkin stuff as well.
