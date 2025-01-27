#!/bin/bash

# Create directory structure
mkdir -p /workspace/ComfyUI/models/{diffusion_models,text_encoders,vae,upscale,loras/HUNYUAN/custom}
mkdir -p /workspace/ComfyUI/custom_nodes

# Install custom nodes
cd /workspace/ComfyUI/custom_nodes

# Install Video Helper Suite
git clone https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite.git
# Install Frame Interpolation
git clone https://github.com/Fannovel16/ComfyUI-Frame-Interpolation.git
# Install Noise Tools
git clone https://github.com/BlenderNeko/ComfyUI_Noise.git
# Install Custom Scripts
git clone https://github.com/pythongosssss/ComfyUI-Custom-Scripts.git

# Save the workflow
cat > /workspace/ComfyUI/workflow.json << 'EOF'
{
  "last_node_id": 104,
  "last_link_id": 242,
  "nodes": [
    # Rest of the workflow JSON content here...
EOF

# Download required model files
cd /workspace/ComfyUI/models

# Models we already have from previous setup
# - clip_l.safetensors
# - llava_llama3_fp8_scaled.safetensors
# - hunyuan_video_t2v_720p_bf16.safetensors
# - hunyuan_video_vae_bf16.safetensors

# Download additional required models
cd upscale
wget -O 4x_foolhardy_Remacri.pth https://huggingface.co/datasets/FacehugmansPics/4x_foolhardy_Remacri/resolve/main/4x_foolhardy_Remacri.pth

cd ../loras/HUNYUAN/custom
wget -O p0rtm4n-hunyuan-v1.1-vfx_ai.safetensors https://civitai.com/api/download/models/293884

# Install additional Python packages required by the custom nodes
cd /workspace/ComfyUI
pip install -r custom_nodes/ComfyUI-VideoHelperSuite/requirements.txt
pip install -r custom_nodes/ComfyUI-Frame-Interpolation/requirements.txt
pip install -r custom_nodes/ComfyUI_Noise/requirements.txt

# Add to the startup script to ensure models are in place
echo "
# Check and create required directories
mkdir -p /workspace/ComfyUI/models/{diffusion_models,text_encoders,vae,upscale,loras/HUNYUAN/custom}

# Ensure workflow is in place
if [ ! -f /workspace/ComfyUI/workflow.json ]; then
    cp /workspace/workflow.json /workspace/ComfyUI/workflow.json
fi
" >> /workspace/start.sh