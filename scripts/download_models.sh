#!/bin/bash
set -e

MODEL_DIR="/ComfyUI/models"
mkdir -p ${MODEL_DIR}/{unet,text_encoders,clip_vision,vae,loras}

# Function to convert bytes to human readable format
human_readable() {
    local bytes=$1
    if [ $bytes -lt 1024 ]; then
        echo "${bytes}B"
    elif [ $bytes -lt 1048576 ]; then
        echo "$(( (bytes + 512)/1024 ))KB"
    else
        echo "$(( (bytes + 524288)/1048576 ))MB"
    fi
}

# Function to download file
download_file() {
    local url=$1
    local dest=$2
    local filename=$(basename "$dest")
    local model_type=$(basename $(dirname "$dest"))

    if [ -f "$dest" ] && [ -s "$dest" ]; then
        echo "✅ $filename already exists in $model_type, skipping"
        return 0
    fi

    case "$filename" in
        "hunyuan_video_720_cfgdistill_bf16.safetensors")
            echo "🎭 Downloading Hunyuan Video UNet model..."
            ;;
        "hunyuan_video_FastVideo_720_fp8_e4m3fn.safetensors")
            echo "🚀 Downloading Hunyuan FastVideo LoRA..."
            ;;
        "Long-ViT-L-14-GmP-SAE-TE-only.safetensors")
            echo "🧠 Downloading LongCLIP Text Encoder..."
            ;;
        "llava_llama3_fp8_scaled.safetensors")
            echo "🦙 Downloading Llava Text Encoder..."
            ;;
        "hunyuan_video_vae_bf16.safetensors")
            echo "🎨 Downloading Hunyuan Video VAE..."
            ;;
        "clip-vit-large-patch14.safetensors")
            echo "👁️ Downloading CLIP Vision model..."
            ;;
    esac

    # Get total size first
    local total_size=$(wget --spider --server-response "$url" 2>&1 | grep "Content-Length" | awk '{print $2}' | tail -1)
    
    # Download with custom progress
    wget "$url" -O "$dest" 2>&1 | \
    while read line; do
        if [[ $line =~ ([0-9]+)%\ +([0-9.]+[GMK])\ +([0-9.]+[GMK])/s\ +([0-9hms]+) ]]; then
            percent="${BASH_REMATCH[1]}"
            speed="${BASH_REMATCH[2]}/s"
            eta="${BASH_REMATCH[4]}"
            printf "\r💾 Progress: %3d%% | Speed: %8s | ETA: %8s" "$percent" "$speed" "$eta"
        fi
    done
    echo -e "\n✨ Successfully downloaded $filename"
    echo "----------------------------------------"
}

echo "🚀 Starting model downloads..."

# Define download tasks
declare -A downloads=(
    ["${MODEL_DIR}/unet/hunyuan_video_720_cfgdistill_bf16.safetensors"]="https://huggingface.co/Kijai/HunyuanVideo_comfy/resolve/main/hunyuan_video_720_cfgdistill_bf16.safetensors"
    ["${MODEL_DIR}/loras/hunyuan_video_FastVideo_720_fp8_e4m3fn.safetensors"]="https://huggingface.co/Kijai/HunyuanVideo_comfy/resolve/main/hunyuan_video_FastVideo_720_fp8_e4m3fn.safetensors"
    ["${MODEL_DIR}/text_encoders/Long-ViT-L-14-GmP-SAE-TE-only.safetensors"]="https://huggingface.co/zer0int/LongCLIP-SAE-ViT-L-14/resolve/main/Long-ViT-L-14-GmP-SAE-TE-only.safetensors"
    ["${MODEL_DIR}/text_encoders/llava_llama3_fp8_scaled.safetensors"]="https://huggingface.co/Comfy-Org/HunyuanVideo_repackaged/resolve/main/split_files/text_encoders/llava_llama3_fp8_scaled.safetensors"
    ["${MODEL_DIR}/vae/hunyuan_video_vae_bf16.safetensors"]="https://huggingface.co/Kijai/HunyuanVideo_comfy/resolve/main/hunyuan_video_vae_bf16.safetensors"
    ["${MODEL_DIR}/clip_vision/clip-vit-large-patch14.safetensors"]="https://huggingface.co/openai/clip-vit-large-patch14/resolve/main/model.safetensors"
)

# Download files sequentially
for dest in "${!downloads[@]}"; do
    url="${downloads[$dest]}"
    download_file "$url" "$dest"
done

echo "🔍 Verifying downloads..."
failed=0
for dir in "unet" "loras" "text_encoders" "clip_vision" "vae"; do
    if [ -d "${MODEL_DIR}/${dir}" ]; then
        for file in "${MODEL_DIR}/${dir}"/*; do
            if [ -f "$file" ]; then
                if [ ! -s "$file" ]; then
                    echo "❌ Error: $(basename "$file") is empty"
                    failed=1
                else
                    echo "✅ $(basename "$file") verified successfully"
                fi
            fi
        done
    fi
done

if [ $failed -eq 0 ]; then
    echo "✨ All models downloaded and verified successfully - NOW GO MAKE SOMETHING COOL"
    exit 0
else
    echo "⚠️ Some models may need to be re-downloaded"
    exit 1
fi