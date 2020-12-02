#!/usr/bin/env bash

# nvidia-docker became docker --gpus all now and probably the NV_GPU flag doesn't work anymore. But maybe someone might want to still use nvidia-docker2 package, so this script needs to become slightly more generic. 
DOCKERAPIVERSION=`docker version --format '{{.Client.APIVersion}}'`
NEWERDOCKERAPI=`echo "$DOCKERAPIVERSION >= 1.49" | bc -l` #use bc so we can do floating point stuff 

#DRYRUN=yes ###comment to actually run this
#REBUILD=yes

PASSWD=$1
MYUSERNAME=$USER #frederico
DOCKERHOSTNAME=`hostname` #poop
THISVOLUMENAME=sshvolume-torch
DOCKERMACHINEIP=172.28.5.30
DOCKERMACHINENAME=tch
MACHINEHOSTNAME=torch_machine2
CATKINWSPATH=/root/catkin_ws
#DOCKERFILE=docker/pytorch/ ## standard should be .
#BUILDINDIR=$PWD/pytorch ##standard should be $PWD
DOCKERFILE=.
BUILDINDIR=$PWD
#export NV_GPU=1
if [ -z "$PASSWD" ]
then
  echo "you need to input your own password to mount the internal ssh volume that is shared between docker and the docker host!"
  echo "usage is: $0 <your-password-here>"
else
  while true; do
    {
    #echo "doing nothing"
    OLDDIR=$PWD
    cd $BUILDINDIR
    if [ -z "$REBUILD" ]
    then
    	nvidia-docker build -t $DOCKERMACHINENAME $DOCKERFILE
    else
        nvidia-docker build --no-cache -t $DOCKERMACHINENAME .
    fi
    cd $OLDDIR
    } ||
    {
    echo "something went wrong..." &&
    break
    }
  echo "STARTING ROS PYTORCH ROS DOCKER..."

  ISTHERENET=`docker network ls | grep br0`
  if [ -z "$ISTHERENET" ]
  then
    echo "docker network br0 not up. creating one..."
    docker network create \
      --driver=bridge \
      --subnet=172.28.0.0/16 \
      --ip-range=172.28.5.0/24 \
      --gateway=172.28.5.254 \
      br0
  else
    echo "found br0 docker network."
  fi

  scripts/enable_forwarding_docker_host.sh
  #nvidia-docker run --rm -it -p 8888:8888 -h $MACHINEHOSTNAME --network=br0 --ip=$DOCKERMACHINEIP $DOCKERMACHINENAME #bash
  {
  echo "creating shared workspace volume"
  docker volume create --driver vieux/sshfs   -o sshcmd=$MYUSERNAME@$DOCKERHOSTNAME:$PWD/catkin_ws -o password=$PASSWD $THISVOLUMENAME
  echo "workspace volume created"
  } ||
  {
    echo "could not mount ssh volume. perhaps vieux is not installed?" &&
    echo "install with: docker plugin install vieux/sshfs" &&
    break
  }
#  nvidia-docker run --rm -it -u root -p 8888:8888 -p 222:22 -e DISPLAY=$DISPLAY -v /tmp/.X11-unix:/tmp/.X11-unix -v $THISVOLUMENAME:/catkin_ws -h $MACHINEHOSTNAME --network=br0 --ip=$DOCKERMACHINEIP $DOCKERMACHINENAME bash # -c "jupyter notebook --port=8888 --no-browser --ip=$DOCKERMACHINEIP --allow-root &" && bash -i

  if [ -z "$DRYRUN" ]
  then
      {
	   if (( NEWERDOCKERAPI ))
	   then
	     {
	     echo "starting docker - new version"
	     docker run --gpus all  --rm -it -u root -e DISPLAY=$DISPLAY -v /tmp/.X11-unix:/tmp/.X11-unix -v $THISVOLUMENAME:$CATKINWSPATH -v /mnt/share:/mnt/share -h $MACHINEHOSTNAME --network=br0 --ip=$DOCKERMACHINEIP $DOCKERMACHINENAME bash # -c "jupyter notebook --port=8888 --no-browser --ip=172.28.5.4 --allow-root &" && bash -i
	     }
	   else
	     {   
	     echo "starting docker - old version"
	     nvidia-docker run --rm -it -u root -e DISPLAY=$DISPLAY -v /tmp/.X11-unix:/tmp/.X11-unix -v $THISVOLUMENAME:$CATKINWSPATH -v /mnt/share:/mnt/share -h $MACHINEHOSTNAME --network=br0 --ip=$DOCKERMACHINEIP $DOCKERMACHINENAME bash # -c "jupyter notebook --port=8888 --no-browser --ip=172.28.5.4 --allow-root &" && bash -i
	     }
	   fi
      }
  else
      {
	     echo "DRY RUN"
	     nvidia-docker run --rm -it -u root -h $MACHINEHOSTNAME --network=br0 --ip=$DOCKERMACHINEIP $DOCKERMACHINENAME bash 
      }
  fi
  ## if I add this with -v I can't catkin_make it with entrypoint...
  #-v /temporal-segment-networks/catkin_ws:$PWD/catkin_ws/src
  #
  docker volume rm $THISVOLUMENAME
  break
  done
fi
