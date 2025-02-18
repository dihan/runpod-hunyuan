#!/bin/bash
set -euo pipefail

MODEL_DIR="/workspace/ComfyUI/models"
mkdir -p ${MODEL_DIR}/{unet,text_encoders,clip_vision,vae,loras}

# Function to format file size
format_size() {
    local size=$1
    if [ $size -ge 1073741824 ]; then
        echo "$(awk "BEGIN {printf \"%.1f\", $size/1073741824}") GB"
    elif [ $size -ge 1048576 ]; then
        echo "$(awk "BEGIN {printf \"%.1f\", $size/1048576}") MB"
    elif [ $size -ge 1024 ]; then
        echo "$(awk "BEGIN {printf \"%.1f\", $size/1024}") KB"
    else
        echo "${size} B"
    fi
}

# Function to download file with progress
download_file() {
    local url=$1
    local dest=$2
    local filename=$(basename "$dest")
    local model_type=$(basename $(dirname "$dest"))
    local max_retries=3
    local retry_count=0

    if [ -f "$dest" ] && [ -s "$dest" ]; then
        echo "✅ $filename already exists in $model_type, skipping"
        return 0
    fi

    while [ $retry_count -lt $max_retries ]; do
        echo "📥 Downloading: $filename"
        echo "📂 Type: $model_type"
        
        # Get file size first
        local size=$(curl -sI "$url" | grep -i content-length | awk '{print $2}' | tr -d '\r')
        local formatted_size=$(format_size $size)
        echo "📊 Total size: $formatted_size"
        
        # Download with progress bar
        if wget --progress=bar:force -O "$dest.tmp" "$url" 2>&1 | \
           stdbuf -o0 awk '/[.] +[0-9][0-9]?[0-9]?%/ { print substr($0,63,3) }' | \
           stdbuf -o0 awk '{printf("\r⏳ Progress: %s%%", $1)}'; then
            mv "$dest.tmp" "$dest"
            echo -e "\n✨ Successfully downloaded $filename ($formatted_size)"
            echo "----------------------------------------"
            return 0
        else
            echo -e "\n⚠️ Failed to download $filename (attempt $((retry_count + 1))/$max_retries)"
            rm -f "$dest.tmp"
            retry_count=$((retry_count + 1))
            if [ $retry_count -lt $max_retries ]; then
                echo "🔄 Retrying in 5 seconds..."
                sleep 5
            fi
        fi
    done

    echo "❌ Failed to download $filename after $max_retries attempts"
    return 1
}

echo "🚀 Starting model downloads..."

# Define download tasks with descriptive names
declare -A downloads=(
    ["${MODEL_DIR}/unet/hunyuan_video_720_cfgdistill_bf16.safetensors"]="https://huggingface.co/Kijai/HunyuanVideo_comfy/resolve/main/hunyuan_video_720_cfgdistill_bf16.safetensors"
    ["${MODEL_DIR}/loras/hunyuan_video_FastVideo_720_fp8_e4m3fn.safetensors"]="https://huggingface.co/Kijai/HunyuanVideo_comfy/resolve/main/hunyuan_video_FastVideo_720_fp8_e4m3fn.safetensors"
    ["${MODEL_DIR}/text_encoders/Long-ViT-L-14-GmP-SAE-TE-only.safetensors"]="https://huggingface.co/zer0int/LongCLIP-SAE-ViT-L-14/resolve/main/Long-ViT-L-14-GmP-SAE-TE-only.safetensors"
    ["${MODEL_DIR}/text_encoders/llava_llama3_fp8_scaled.safetensors"]="https://huggingface.co/Comfy-Org/HunyuanVideo_repackaged/resolve/main/split_files/text_encoders/llava_llama3_fp8_scaled.safetensors"
    ["${MODEL_DIR}/vae/hunyuan_video_vae_bf16.safetensors"]="https://huggingface.co/Kijai/HunyuanVideo_comfy/resolve/main/hunyuan_video_vae_bf16.safetensors"
    ["${MODEL_DIR}/clip_vision/clip-vit-large-patch14.safetensors"]="https://huggingface.co/openai/clip-vit-large-patch14/resolve/main/model.safetensors"
)

# Track overall success
download_success=true
total_files=${#downloads[@]}
current_file=1

# Download files sequentially with progress tracking
for dest in "${!downloads[@]}"; do
    url="${downloads[$dest]}"
    echo "📦 Processing file $current_file of $total_files"
    if ! download_file "$url" "$dest"; then
        download_success=false
        echo "⚠️ Failed to download $(basename "$dest") - continuing with other downloads"
    fi
    current_file=$((current_file + 1))
done

# Final verification
echo "🔍 Verifying downloads..."
verification_failed=false
for dir in "unet" "loras" "text_encoders" "clip_vision" "vae"; do
    if [ -d "${MODEL_DIR}/${dir}" ]; then
        for file in "${MODEL_DIR}/${dir}"/*; do
            if [ -f "$file" ]; then
                size=$(stat -f%z "$file" 2>/dev/null || stat -c%s "$file")
                if [ "$size" -eq 0 ]; then
                    echo "❌ Error: $(basename "$file") is empty"
                    verification_failed=true
                else
                    formatted_size=$(format_size $size)
                    echo "✅ $(basename "$file") verified successfully ($formatted_size)"
                fi
            fi
        done
    fi
done

if [ "$download_success" = true ] && [ "$verification_failed" = false ]; then
    echo "✨ All models downloaded and verified successfully"
    exit 0
else
    echo "⚠️ Some models failed to download or verify"
    exit 1
fi