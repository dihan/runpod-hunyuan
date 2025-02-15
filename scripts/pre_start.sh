#!/bin/bash

export PYTHONUNBUFFERED=1

echo "**** syncing venv to workspace, please wait. This could take a while on first startup! ****"
rsync -au --remove-source-files /venv/ /workspace/venv/ && rm -rf /venv

echo "**** syncing ComfyUI to workspace, please wait ****"
rsync -au --remove-source-files /ComfyUI/ /workspace/ComfyUI/ && rm -rf /ComfyUI

echo "**** downloading models, please wait ****"
/download_models.sh

source /workspace/venv/bin/activate
cd /workspace/ComfyUI
python main.py --listen --port 3000 $COMFYUI_EXTRA_ARGS &