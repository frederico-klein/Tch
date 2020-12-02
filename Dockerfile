FROM nvidia/cuda:9.0-cudnn7-devel-ubuntu16.04
ARG PYTHON_VERSION=3.6
ENV DEBIAN_FRONTEND noninteractive
RUN apt-get update && apt-get install -y --no-install-recommends --fix-missing \
         build-essential \
         cmake \
         git \
         curl \
         wget \
         vim \
         ca-certificates \
         libjpeg-dev \
         libpng-dev \
 	 python3-pip \
  	 python-pip \
  	 openssh-server\
  	 libssl-dev \
	 tar\
  	 libboost-all-dev \
	 && apt-get clean && rm -rf /tmp/* /var/tmp/*

############# needs sshd and ros with python3 running (copy what I did for fr machine)

RUN mkdir /var/run/sshd \
    && echo 'root:ros_ros' | chpasswd \
    && sed -i 's/PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config \
    && sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd

ENV NOTVISIBLE "in users profile"
RUN echo "export VISIBLE=now" >> /etc/profile

EXPOSE 22

#### torch stuff
RUN wget https://repo.continuum.io/miniconda/Miniconda3-latest-Linux-x86_64.sh  && \
     mv Miniconda3-latest-Linux-x86_64.sh miniconda.sh && \
     chmod +x miniconda.sh && \
     ./miniconda.sh -b -p /opt/conda && \
     rm ./miniconda.sh && \
     /opt/conda/bin/conda update -n root conda && \
     /opt/conda/bin/conda install -y python=$PYTHON_VERSION numpy pyyaml scipy ipython mkl mkl-include cython typing && \
     /opt/conda/bin/conda install -y -c pytorch magma-cuda90 && \
     /opt/conda/bin/conda clean -ya

ENV PATH /opt/conda/bin:$PATH
#RUN pip install ninja
# This must be done before pip so that requirements.txt is available
WORKDIR /opt

### actual old torch

RUN git clone --recursive https://github.com/mysablehats/pytorch.git
RUN cd pytorch && TORCH_CUDA_ARCH_LIST="3.5 5.2 6.0 6.1 7.0+PTX" TORCH_NVCC_FLAGS="-Xfatbin -compress-all" \
    CMAKE_PREFIX_PATH="$(dirname $(which conda))/../" \
    pip install -v .


####


#add my snazzy banner ## I need this because it is referenced on the entrypoint!
ADD banner.txt /root/

ADD scripts/entrypoint.sh /root/
ENTRYPOINT ["/root/entrypoint.sh"]
###needs the catkin stuff as well.
