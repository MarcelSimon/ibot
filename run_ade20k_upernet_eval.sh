#!/usr/bin/env bash
set -e 

# Configuration
# Use absolute paths or VARIABLE="$(realpath 'my/relative/path')"
IBOT_DIR=/path/to/ibot
IMAGE_NAME="marcel.simon_ibot"
CONTAINER_NAME="$IMAGE_NAME"
BASE_DIR=/path/to/pre-trained/model
CHECKPOINT=$BASE_DIR/checkpoint.final.pth
OUTPUT_DIR=$BASE_DIR/ade20k-results
DATA_ROOT=/path/to/ADEChallengeData2016
VISIBLE_GPUS=0,1,2,3

# Script starts here
NUM_GPUS=$(echo "${VISIBLE_GPUS}" | awk -F',' '{print NF}')

mkdir -p "/${OUTPUT_DIR}/seg"
cp "$(realpath "$0")" "${OUTPUT_DIR}/seg/" \
&& docker run \
    -it \
    --rm \
    --init \
    --gpus "\"device=$VISIBLE_GPUS\"" \
    --ipc=host \
    --ulimit memlock=-1 \
    --ulimit stack=67108864 \
    -e PRETRAINED="/data/$CHECKPOINT" \
    -e OUTPUT_DIR="/data/$OUTPUT_DIR" \
    -e "LOCAL_UID=$(id -u)" \
    -e "LOCAL_GID=$(id -g)" \
    -v /:/data \
    --name $CONTAINER_NAME \
    $IMAGE_NAME \
    /bin/sh -c "\
        cd \"/data/${IBOT_DIR}/\" \
        && bash run.sh \
            ade20k_seg \
            vino_ade20k_seg_eval \
            vit_small \
            teacher \
            $NUM_GPUS \
            data.samples_per_gpu=4 \
            data.workers_per_gpu=4 \
            model.backbone.out_with_norm=true \
            optimizer.lr=3e-5 \
            data.train.data_root=/data/$DATA_ROOT \
            data.val.data_root=/data/$DATA_ROOT \
            data.test.data_root=/data/$DATA_ROOT \
            2>&1 | tee -a \"/data/${OUTPUT_DIR}/seg/semseg.log\" \
    "
