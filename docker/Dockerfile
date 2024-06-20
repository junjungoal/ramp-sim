##
## Copyright (c) 2023 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
##
## NVIDIA CORPORATION, its affiliates and licensors retain all intellectual
## property and proprietary rights in and to this material, related
## documentation and any modifications thereto. Any use, reproduction,
## disclosure or distribution of this material and related documentation
## without an express license agreement from NVIDIA CORPORATION or
## its affiliates is strictly prohibited.
##
ARG DEBIAN_FRONTEND=noninteractive
ARG BASE_DIST=ubuntu20.04
ARG CUDA_VERSION=11.4.2
ARG ISAAC_SIM_VERSION=2023.1.0


FROM nvcr.io/nvidia/isaac-sim:${ISAAC_SIM_VERSION} AS isaac-sim
FROM nvcr.io/nvidia/cudagl:${CUDA_VERSION}-devel-${BASE_DIST}

RUN apt-get update

LABEL maintainer "Jun Yamada"

ARG VULKAN_SDK_VERSION=1.3.224.1

# Deal with getting tons of debconf messages
# See: https://github.com/phusion/baseimage-docker/issues/58
RUN echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections

# Set timezone info
RUN apt-get update && apt-get install -y \
    tzdata \
    software-properties-common \
    && rm -rf /var/lib/apt/lists/* \
    && ln -fs /usr/share/zoneinfo/America/Los_Angeles /etc/localtime \
    && echo "Europe/London" > /etc/timezone \
    && dpkg-reconfigure -f noninteractive tzdata \
    && add-apt-repository -y ppa:git-core/ppa \
    && apt-get update && apt-get install -y \
    curl \
    lsb-core \
    wget \
    build-essential \
    cmake \
    git \
    git-lfs \
    iputils-ping \
    make \
    openssh-server \
    openssh-client \
    libeigen3-dev \
    libssl-dev \
    python3-pip \
    python3-ipdb \
    python3-tk \
    python3-wstool \
    sudo git bash unattended-upgrades \
    apt-utils \
    terminator \
    && rm -rf /var/lib/apt/lists/*


# https://catalog.ngc.nvidia.com/orgs/nvidia/containers/cudagl

RUN apt-get update && apt-get install -y --no-install-recommends \
    libatomic1 \
    libegl1 \
    libglu1-mesa \
    libgomp1 \
    libsm6 \
    libxi6 \
    libxrandr2 \
    libxt6 \
    libfreetype-dev \
    libfontconfig1 \
    openssl \
    libssl1.1 \
    wget \
    vulkan-utils \
&& apt-get -y autoremove \
&& apt-get clean autoclean \
&& rm -rf /var/lib/apt/lists/*



# Download the Vulkan SDK and extract the headers, loaders, layers and binary utilities
RUN wget -q --show-progress \
    --progress=bar:force:noscroll \
    https://sdk.lunarg.com/sdk/download/${VULKAN_SDK_VERSION}/linux/vulkansdk-linux-x86_64-${VULKAN_SDK_VERSION}.tar.gz \
    -O /tmp/vulkansdk-linux-x86_64-${VULKAN_SDK_VERSION}.tar.gz \ 
    && echo "Installing Vulkan SDK ${VULKAN_SDK_VERSION}" \
    && mkdir -p /opt/vulkan \
    && tar -xf /tmp/vulkansdk-linux-x86_64-${VULKAN_SDK_VERSION}.tar.gz -C /opt/vulkan \
    && mkdir -p /usr/local/include/ && cp -ra /opt/vulkan/${VULKAN_SDK_VERSION}/x86_64/include/* /usr/local/include/ \
    && mkdir -p /usr/local/lib && cp -ra /opt/vulkan/${VULKAN_SDK_VERSION}/x86_64/lib/* /usr/local/lib/ \
    && cp -a /opt/vulkan/${VULKAN_SDK_VERSION}/x86_64/lib/libVkLayer_*.so /usr/local/lib \
    && mkdir -p /usr/local/share/vulkan/explicit_layer.d \
    && cp /opt/vulkan/${VULKAN_SDK_VERSION}/x86_64/etc/vulkan/explicit_layer.d/VkLayer_*.json /usr/local/share/vulkan/explicit_layer.d \
    && mkdir -p /usr/local/share/vulkan/registry \
    && cp -a /opt/vulkan/${VULKAN_SDK_VERSION}/x86_64/share/vulkan/registry/* /usr/local/share/vulkan/registry \
    && cp -a /opt/vulkan/${VULKAN_SDK_VERSION}/x86_64/bin/* /usr/local/bin \
    && ldconfig \
    && rm /tmp/vulkansdk-linux-x86_64-${VULKAN_SDK_VERSION}.tar.gz && rm -rf /opt/vulkan


# Setup the required capabilities for the container runtime    
ENV NVIDIA_VISIBLE_DEVICES=all NVIDIA_DRIVER_CAPABILITIES=all

# Open ports for live streaming
EXPOSE 47995-48012/udp \
       47995-48012/tcp \
       49000-49007/udp \
       49000-49007/tcp \
       49100/tcp \
       8011/tcp \
       8012/tcp \
       8211/tcp \
       8899/tcp \
       8891/tcp

ENV OMNI_SERVER http://omniverse-content-production.s3-us-west-2.amazonaws.com/Assets/Isaac/${ISAAC_SIM_VERSION}
ENV MIN_DRIVER_VERSION 525.60.11
ENV TORCH_CUDA_ARCH_LIST="7.0+PTX"



ENV LANG C.UTF-8
ENV TZS=Europe/London
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

RUN apt-get update && \
    apt-get install -y sudo

ARG USER
ARG PASSWD
ARG USER_ID

ENV HOME /home/$USER

RUN groupadd -g $USER_ID -o $USER && \
    useradd -m $USER -u $USER_ID -g $USER_ID && \
    gpasswd -a $USER sudo && \
    echo "$USER:$PASSWD" | chpasswd && \
    echo 'Defaults visiblepw' >> /etc/sudoers && \
    echo "$USER ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

USER $USER
WORKDIR $HOME
ENV HOME $HOME


# Copy Isaac Sim files
COPY --chown=$USER:$USER --from=isaac-sim /isaac-sim /isaac-sim
RUN mkdir -p /home/$USER/.nvidia-omniverse/config
COPY --from=isaac-sim /root/.nvidia-omniverse/config /home/$USER/.nvidia-omniverse/config
COPY --from=isaac-sim /etc/vulkan/icd.d/nvidia_icd.json /etc/vulkan/icd.d/nvidia_icd.json
COPY --from=isaac-sim /etc/vulkan/icd.d/nvidia_icd.json /etc/vulkan/implicit_layer.d/nvidia_layers.json


# create an alias for omniverse python
ENV omni_python='/isaac-sim/python.sh'
RUN /isaac-sim/python.sh -m pip install -U pip

RUN echo "alias omni_python='/isaac-sim/python.sh'" >> $HOME/.bashrc


# Add cache date to avoid using cached layers older than this
ARG CACHE_DATE=2023-12-15 

RUN $omni_python -m pip install "robometrics[evaluator] @ git+https://github.com/fishbotics/robometrics.git"

# if you want to use a different version of curobo, create folder as docker/pkgs and put your
# version of curobo there. Then uncomment below line and comment the next line that clones from 
# github

# COPY pkgs /pkgs

RUN mkdir $HOME/pkgs && cd $HOME/pkgs && git clone https://github.com/NVlabs/curobo.git

RUN $omni_python -m pip install ninja wheel tomli


RUN cd $HOME/pkgs/curobo && $omni_python -m pip install .[dev] --no-build-isolation
RUN cd $HOME/pkgs/curobo && $omni_python -m pip install .[isaacsim] --no-build-isolation

# Optionally install nvblox:

RUN sudo apt-get update && \
    sudo apt-get install -y curl tcl && \
    sudo rm -rf /var/lib/apt/lists/*



# install gflags and glog statically, instructions from: https://github.com/nvidia-isaac/nvblox/blob/public/docs/redistributable.md


RUN cd $HOME/pkgs && wget https://cmake.org/files/v3.27/cmake-3.27.1.tar.gz && \
    tar -xvzf cmake-3.27.1.tar.gz && \
    sudo apt update &&  sudo apt install -y build-essential checkinstall zlib1g-dev libssl-dev && \
    cd cmake-3.27.1 && ./bootstrap && \
    make -j8 && \
    sudo make install &&  sudo rm -rf /var/lib/apt/lists/*


ENV USE_CX11_ABI=0
ENV PRE_CX11_ABI=ON



RUN cd $HOME/pkgs && git clone https://github.com/sqlite/sqlite.git -b version-3.39.4 && \
    cd $HOME/pkgs/sqlite && CFLAGS=-fPIC ./configure --prefix=/pkgs/sqlite/install/ && \
    make && sudo make install



RUN cd $HOME/pkgs && git clone https://github.com/google/glog.git -b v0.6.0 && \
    cd glog && \
    mkdir build && cd build && \
    cmake .. -DCMAKE_POSITION_INDEPENDENT_CODE=ON \
    -DCMAKE_INSTALL_PREFIX=/pkgs/glog/install/ \
    -DWITH_GFLAGS=OFF -DWITH_GTEST=OFF -DBUILD_SHARED_LIBS=OFF -DCMAKE_CXX_FLAGS=-D_GLIBCXX_USE_CXX11_ABI=${USE_CX11_ABI} \
    && make -j8 && sudo make install


RUN cd $HOME/pkgs && git clone https://github.com/gflags/gflags.git -b v2.2.2 && \
    cd gflags &&  \
    mkdir build && cd build && \
    cmake .. -DCMAKE_POSITION_INDEPENDENT_CODE=ON \
    -DCMAKE_INSTALL_PREFIX=/pkgs/gflags/install/ \
    -DGFLAGS_BUILD_STATIC_LIBS=ON -DCMAKE_CXX_FLAGS=-D_GLIBCXX_USE_CXX11_ABI=${USE_CX11_ABI} \
    && make -j8 && sudo make install

RUN cd $HOME/pkgs &&  git clone https://github.com/valtsblukis/nvblox.git && cd $HOME/pkgs/nvblox/nvblox && \
    mkdir build && cd build && \
    cmake ..  -DBUILD_REDISTRIBUTABLE=ON \
    -DCMAKE_CXX_FLAGS=-D_GLIBCXX_USE_CXX11_ABI=${USE_CX11_ABI}  -DPRE_CXX11_ABI_LINKABLE=${PRE_CX11_ABI} \
    -DSQLITE3_BASE_PATH="/pkgs/sqlite/install/" -DGLOG_BASE_PATH="/pkgs/glog/install/" \
    -DGFLAGS_BASE_PATH="/pkgs/gflags/install/" -DCMAKE_CUDA_FLAGS=-D_GLIBCXX_USE_CXX11_ABI=${USE_CX11_ABI} \
    -DBUILD_TESTING=OFF && \
    make -j32 && \
    sudo make install

# we also need libglog for pytorch:
RUN cd $HOME/pkgs/glog && \
    mkdir build_isaac && cd build_isaac && \
    cmake .. -DCMAKE_POSITION_INDEPENDENT_CODE=ON \
    -DWITH_GFLAGS=OFF -DWITH_GTEST=OFF -DBUILD_SHARED_LIBS=OFF -DCMAKE_CXX_FLAGS=-D_GLIBCXX_USE_CXX11_ABI=${USE_CX11_ABI} \
    && make -j8 &&sudo make install

RUN cd $HOME/pkgs && git clone https://github.com/nvlabs/nvblox_torch.git && \
    cd $HOME/pkgs/nvblox_torch && \
    sh install_isaac_sim.sh $($omni_python -c 'import torch.utils; print(torch.utils.cmake_prefix_path)') && \
    $omni_python -m pip install -e .

# install realsense for nvblox demos:
RUN $omni_python -m pip install pyrealsense2 opencv-python transforms3d


RUN APT_INSTALL="sudo apt-get install -y --no-install-recommends" && \
    sudo apt-get update --fix-missing && \
    DEBIAN_FRONTEND=noninteractive $APT_INSTALL \
        build-essential \
        apt-utils \
        ca-certificates \
        wget \
        git \
        vim \
        libssl-dev \
        curl \
        unzip \
        unrar \
        tmux \
        libopenmpi-dev \
        python3-mpi4py


RUN PIP_INSTALL="/isaac-sim/python.sh -m pip --no-cache-dir install --upgrade" && \
    $PIP_INSTALL \
        numpy \
        scipy \
        cloudpickle \
        Cython \
        tqdm \
        h5py \
        pyyaml \
        wandb  \
        scipy \
        scikit-image>=0.14.2 \
        scikit-learn \
        matplotlib \
        opencv_python \
        trimesh \
        python-fcl \
        urdfpy \
        moviepy \
        imageio \
        patchelf \
        funcsigs \
        mpi4py \
        tensordict==0.2.1 \
        pyrootutils


RUN echo 'alias python=/isaac-sim/python.sh' >> ~/.zshrc
RUN echo "alias pip='/isaac-sim/python.sh -m pip --no-cache-dir'" >> $HOME/.zshrc

RUN $omni_python -m pip install "robometrics[evaluator] @ git+https://github.com/fishbotics/robometrics.git"

RUN mkdir -p ~/projects

RUN sudo ldconfig && \
    sudo apt-get clean && \
    sudo apt-get -y  autoremove && \
    sudo rm -rf /var/lib/apt/lists/* /tmp/*
