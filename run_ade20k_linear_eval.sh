#!/usr/bin/env bash
set -e 

IBOT_DIR=/path/to/ibot

#!/bin/bash

# Define clear variables for maintainability
IMAGE_NAME="ibot"
CONTAINER_NAME="$IMAGE_NAME"
BASE_DIR=/path/to/pre-trained/model
CHECKPOINT=$BASE_DIR/checkpoint.pth
OUTPUT_DIR=$BASE_DIR/ade20k-results
DATA_ROOT=/path/to/ADEChallengeData2016

# Run Docker container with explicit merged parameters

docker run \
    -it \
    --rm \
    --init \
    --gpus '"device=1,2,3,4"' \
    --ipc=host \
    --ulimit memlock=-1 \
    --ulimit stack=67108864 \
    -e PRETRAINED=/data/$CHECKPOINT \
    -e OUTPUT_DIR=/data/$OUTPUT_DIR \
    -e "LOCAL_UID=$(id -u)" \
    -e "LOCAL_GID=$(id -g)" \
    -v /:/data \
    --name $CONTAINER_NAME \
    $IMAGE_NAME \
    /bin/sh -c "\
        mkdir -p \"/data/$OUTPUT_DIR\" \
        && cd /data/$IBOT_DIR/ \
        && bash run.sh \
            ade20k_seg \
            vino_ade20k_seg_eval \
            vit_small \
            teacher \
            2 \
            data.samples_per_gpu=4 \
            data.workers_per_gpu=4 \
            model.backbone.out_with_norm=true \
            optimizer.lr=3e-5 \
            data_root=/data/$DATA_ROOT \
        "
