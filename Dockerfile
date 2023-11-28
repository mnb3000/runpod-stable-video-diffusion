FROM nvidia/cuda:11.8.0-devel-ubuntu22.04

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive
ENV SHELL=/bin/bash

# Set the working directory
WORKDIR /

# Default env vars
ENV MODEL_MOUNTPOINT="/workspace"
ENV PORT=3000

# Update, upgrade, install packages and clean up
RUN apt-get update --yes && \
    apt-get upgrade --yes && \
    apt install --yes --no-install-recommends git git-lfs wget curl bash libgl1 software-properties-common openssh-server ffmpeg && \
    add-apt-repository ppa:deadsnakes/ppa && \
    apt install "python3.10-dev" -y --no-install-recommends && \
    apt-get autoremove -y && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    echo "en_US.UTF-8 UTF-8" > /etc/locale.gen

# Set up Python and pip
RUN ln -s /usr/bin/python3.10 /usr/bin/python && \
    rm /usr/bin/python3 && \
    ln -s /usr/bin/python3.10 /usr/bin/python3 && \
    curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py && \
    python get-pip.py

RUN pip install --upgrade --no-cache-dir pip


RUN mkdir -p /usr/share/svd

WORKDIR /usr/share/svd

RUN git clone https://github.com/Stability-AI/generative-models.git

WORKDIR /usr/share/svd/generative-models

RUN pip install --upgrade --no-cache-dir -r requirements/pt2.txt && \ 
    pip install --upgrade --no-cache-dir . && \
    pip install --upgrade --no-cache-dir streamlit

ENV PYTHONPATH="/usr/share/svd/generative-models"

RUN git lfs install

ENV PORT=3000

RUN mkdir checkpoints

COPY start.sh /start.sh

CMD [ "/start.sh" ]
