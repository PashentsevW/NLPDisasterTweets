ARG BASE_IMAGE=ubuntu:18.04

FROM ${BASE_IMAGE}

ARG USERNAME
ARG USER_UID
ARG USER_GID

RUN groupadd --gid ${USER_GID} ${USERNAME} \
    || useradd --uid ${USER_UID} --gid ${USER_GID} -m ${USERNAME} -s /bin/bash \
    && apt-get update \
    && apt-get install -y sudo \
    && echo ${USERNAME} ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/${USERNAME} \
    && chmod 0440 /etc/sudoers.d/${USERNAME}

USER ${USERNAME}

RUN sudo apt-get update \
    && sudo apt-get install -y --no-install-recommends \
        git \
        curl \
        wget \
        unzip \
        build-essential \
        ca-certificates \
    && sudo rm -rf /var/lib/apt/lists/*

WORKDIR /home/${USERNAME}

ARG CONDA_VERSION
ARG CONDA_PYTHON_VERSION
ARG CONDA_OS
ARG CONDA_PLATFORM
ARG CONDA_INSTALL_PATH=/opt/miniconda3

RUN wget -O miniconda3.sh \
        https://repo.anaconda.com/miniconda/Miniconda3-${CONDA_PYTHON_VERSION}_${CONDA_VERSION}-${CONDA_OS}-${CONDA_PLATFORM}.sh \
    && sudo bash miniconda3.sh -b -p ${CONDA_INSTALL_PATH} \
    && sudo chown -R ${USER_UID}:${USER_GID} ${CONDA_INSTALL_PATH} /home/${USERNAME}/.conda \
    && rm -f miniconda3.sh
ENV PATH ${CONDA_INSTALL_PATH}/bin:$PATH

RUN conda install -c conda-forge --name base ipykernel -y \
    && conda clean -yc

ARG CMAKE_VERSION
ARG CMAKE_OS
ARG CMAKE_PLATFORM
ARG CMAKE_INSTALL_PATH=/opt/cmake-${CMAKE_VERSION}

RUN wget -O cmake.tar.gz \
        https://github.com/Kitware/CMake/releases/download/v${CMAKE_VERSION}/cmake-${CMAKE_VERSION}-${CMAKE_OS}-${CMAKE_PLATFORM}.tar.gz \
    && tar -xzf cmake.tar.gz \
    && sudo mv cmake-${CMAKE_VERSION}-${CMAKE_OS}-${CMAKE_PLATFORM} ${CMAKE_INSTALL_PATH} \
    && sudo ln -s ${CMAKE_INSTALL_PATH}/bin/cmake /usr/bin/cmake \
    && rm -f cmake.tar.gz
ENV PATH ${CMAKE_INSTALL_PATH}/bin/:$PATH

ARG CLANG_LLVM_VERSION=12

RUN wget https://apt.llvm.org/llvm.sh \
    && sudo apt-get update \
    && sudo apt-get install -y --no-install-recommends lsb-release wget software-properties-common gnupg \
    && chmod +x llvm.sh \
    && sudo ./llvm.sh ${CLANG_LLVM_VERSION} \
    && sudo ln -s /usr/lib/llvm-12/bin/clang++ /usr/bin/clang++ \
    && sudo ln -s /usr/lib/llvm-12/bin/clang /usr/bin/clang \
    && rm -f llvm.sh

RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add - \
    && echo "deb https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list \
    && sudo apt-get update \
    && sudo apt-get install -y --no-install-recommends npm ninja-build \
    && sudo npm install --global yarn \
    && sudo npm install --global n \
    && sudo n 16.20.0

RUN pip install --upgrade pip \
    && pip install \
        conan==1.59 \
        git+https://github.com/catboost/catboost.git#subdirectory=catboost/python-package

COPY requirements.txt requirements.txt
RUN pip install --upgrade pip \
    && pip install -r requirements.txt \
    && rm -f requirements.txt
