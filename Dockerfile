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

COPY requirements.txt requirements.txt
RUN pip install --upgrade pip \
    && pip install -r requirements.txt \
    && rm -f requirements.txt
