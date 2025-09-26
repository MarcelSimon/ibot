#!/usr/bin/env bash
set -e

# Configuration, use absolute paths!
IBOT_DIR=/ssd6/home/marcel.simon/src/playground/ibot
IMAGE_NAME="marcel.simon_ibot"
CONTAINER_NAME="${IMAGE_NAME}_2"
DATA_PATH="/ssd6/home/marcel.simon/data/WTours/venice_images/"
OUTPUT_DIR="${IBOT_DIR}/debugging/"
EXTRA_GROUP_IDS="100" # Addition GIDs to give to the Docker user, separated by spaces.
ARCH="vit_small_ibot"
NUM_WORKERS=5
VISIBLE_GPUS=0,1,2,3

# Script starts here
NUM_GPUS=$(echo "${VISIBLE_GPUS}" | awk -F',' '{print NF}')

# Backup code
mkdir -p "/${OUTPUT_DIR}/code"
cp "$(realpath "$0")" "${OUTPUT_DIR}/code/"
cp "${IBOT_DIR}/"*.py "${OUTPUT_DIR}/code/"
# Run training
# Note that we call torch.hub.list() before the training as the script
# may fail if all childs try to download the same files at the same time
docker run \
    -it \
    --rm \
    --init \
    --gpus "\"device=$VISIBLE_GPUS\"" \
    --ipc=host \
    --ulimit memlock=-1 \
    --ulimit stack=67108864 \
    -e "LOCAL_UID=$(id -u)" \
    -e "LOCAL_GID=$(id -g)" \
    -e "LOCAL_EXTRA_GIDS=${EXTRA_GROUP_IDS}" \
    -v /:/data \
    --name $CONTAINER_NAME \
    $IMAGE_NAME \
    /bin/sh -c "\
        python -c 'import torch; torch.hub.list(\"facebookresearch/xcit:main\")' \
        && cd \"/data/${IBOT_DIR}/\" \
        && python -m torch.distributed.launch \
            --nproc_per_node=${NUM_GPUS} \
            main_ibot.py \
                --arch ${ARCH} \
                --data_path /data/${DATA_PATH} \
                --output_dir /data/${OUTPUT_DIR} \
                --num_workers ${NUM_WORKERS} \
                --shared_head True \
                --global_crops_scale 0.25 1.0 \
                --batch_size_per_gpu 96 \
            2>&1 | tee -a \"/data/${OUTPUT_DIR}/training.log\" \
    "

                #--batch_size_per_gpu 40 \