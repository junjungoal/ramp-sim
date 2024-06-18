xhost +
docker run --name ramp-sim --entrypoint bash -it -d --gpus all -e "ACCEPT_EULA=Y" -e HOST_UID=${UID} -e USER=${USER} -e DISPLAY=$DISPLAY --network=host --privileged \
    -e "PRIVACY_CONSENT=Y" \
    -v /home/$USER/.Xauthority:/home/$USER/.Xauthority \
    -v /home/$USER/projects/:/home/$USER/projects/ -v /home/$USER/.ssh/:/home/$USER/.ssh/ --shm-size=1gb \
    -v ~/docker/isaac-sim/cache/kit:/isaac-sim/kit/cache:rw \
    -v ~/docker/isaac-sim/cache/ov:/home/$USER/.cache/ov:rw \
    -v ~/docker/isaac-sim/cache/pip:/home/$USER/.cache/pip:rw \
    -v ~/docker/isaac-sim/cache/glcache:/home/$USER/.cache/nvidia/GLCache:rw \
    -v ~/docker/isaac-sim/cache/computecache:/home/$USER/.nv/ComputeCache:rw \
    -v ~/docker/isaac-sim/logs:/home/$USER/.nvidia-omniverse/logs:rw \
    -v ~/docker/isaac-sim/data:/home/$USER/.local/share/ov/data:rw \
    -v ~/docker/isaac-sim/documents:/home/$USER/Documents:rw \
    -v /tmp/.X11-unix:/tmp/.X11-unix \
    -v /dev:/dev \
    ramp-sim
