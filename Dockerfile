FROM nvcr.io/nvidia/pytorch:20.12-py3 as base

ARG DEBIAN_FRONTEND=noninteractive
ARG USERNAME=vscode
ARG USER_UID=10000
ARG USER_GID=10000

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

# System dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    tmux \
    sudo \
    gosu \
    git \
    libgl1-mesa-glx \
    && rm -rf /var/lib/apt/lists/*

# We freeze all existing package to avoid that pytorch apex etc get overriden
# by newer versions, which don't work anymore with ibot
RUN pip freeze > constraints.txt

# Install MMCV separately (CUDA 11.0, iBot uses Torch 1.7.1
RUN pip install \
    --no-cache-dir \
    --upgrade-strategy only-if-needed \
    -c constraints.txt \
    -f https://download.openmmlab.com/mmcv/dist/cu110/torch1.8.0/index.html \
    mmcv-full==1.3.9 \
    && cd ..

# Additional Python dependencies
RUN pip3 install --no-cache-dir --upgrade-strategy only-if-needed \
    -c constraints.txt \
    pytest-runner \
    scipy \
    tensorboardX \
    faiss-gpu==1.6.1 \
    tqdm \
    lmdb \
    scikit-learn \
    pyarrow==2.0.0 \
    timm \
    DALL-E \
    munkres \
    six \
    einops \
    mkl \
    cyanure \
    yapf==0.30

# Install MMDetection (Swin Transformer Object Detection)
RUN git clone https://github.com/SwinTransformer/Swin-Transformer-Object-Detection.git \
    && cd Swin-Transformer-Object-Detection \
    && pip3 install --upgrade-strategy only-if-needed \
        -c ../constraints.txt \
        --no-cache-dir -r requirements/build.txt \
    && pip3 install --upgrade-strategy only-if-needed \
        -c ../constraints.txt \
        -v -e . \
    && cd ..

# Install MMSegmentation v0.12.0
RUN git clone -b v0.12.0 https://github.com/open-mmlab/mmsegmentation.git \
    && cd mmsegmentation \
    && pip3 install \
    -c ../constraints.txt \
    --upgrade-strategy only-if-needed -v -e . \
    && cd ..

# Cleanup pip cache
RUN rm -rf ~/.cache/pip

# Create non-root user
RUN groupadd --gid ${USER_GID} ${USERNAME} \
    && useradd --uid ${USER_UID} --gid ${USER_GID} -m ${USERNAME} \
    && usermod -aG sudo ${USERNAME} \
    && echo "${USERNAME} ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers \
    && chown -R ${USERNAME}:${USERNAME} /home/${USERNAME} \
    && chmod -R 700 /home/${USERNAME}

# Add custom entrypoint
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]

WORKDIR /workspace
