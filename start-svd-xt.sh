#!/bin/bash
set -e # Exit the script if any statement returns a non-true return value

# ---------------------------------------------------------------------------- #
#                          Function Definitions                                #
# ---------------------------------------------------------------------------- #

# Execute script if exists
execute_script() {
    local script_path=$1
    local script_msg=$2
    if [[ -f ${script_path} ]]; then
        echo "${script_msg}"
        bash "${script_path}"
    fi
}

# Setup ssh
setup_ssh() {
    if [[ $PUBLIC_KEY ]]; then
        echo "Setting up SSH..."
        mkdir -p ~/.ssh
        echo "$PUBLIC_KEY" >>~/.ssh/authorized_keys
        chmod 700 -R ~/.ssh

        if [ ! -f /etc/ssh/ssh_host_rsa_key ]; then
            ssh-keygen -t rsa -f /etc/ssh/ssh_host_rsa_key -q -N ''
        fi

        if [ ! -f /etc/ssh/ssh_host_dsa_key ]; then
            ssh-keygen -t dsa -f /etc/ssh/ssh_host_dsa_key -q -N ''
        fi

        if [ ! -f /etc/ssh/ssh_host_ecdsa_key ]; then
            ssh-keygen -t ecdsa -f /etc/ssh/ssh_host_ecdsa_key -q -N ''
        fi

        if [ ! -f /etc/ssh/ssh_host_ed25519_key ]; then
            ssh-keygen -t ed25519 -f /etc/ssh/ssh_host_ed25519_key -q -N ''
        fi

        service ssh start

        echo "SSH host keys:"
        cat /etc/ssh/*.pub
    fi
}

# Export env vars
export_env_vars() {
    echo "Exporting environment variables..."
    printenv | grep -E '^RUNPOD_|^PATH=|^_=' | awk -F = '{ print "export " $1 "=\"" $2 "\"" }' >>/etc/rp_environment
    echo 'source /etc/rp_environment' >>~/.bashrc
}

start_streamlit() {
    cd /usr/share/svd/generative-models
    streamlit run scripts/demo/video_sampling.py --server.port $PORT --server.enableCORS=false
}

create_symlinks() {
    echo "Creating .safetensor file symlinks..."
    ln -s $MODEL_MOUNTPOINT/stable-video-diffusion-img2vid-xt/svd_xt.safetensors ./checkpoints/svd_xt.safetensors
    ln -s $MODEL_MOUNTPOINT/stable-video-diffusion-img2vid-xt/svd_xt_image_decoder.safetensors ./checkpoints/svd_xt_image_decoder.safetensors
}

check_workspace() {
    echo -n "Checking if $MODEL_MOUNTPOINT exists..."
    if [ ! -d $MODEL_MOUNTPOINT ]; then
        echo -e "\n$MODEL_MOUNTPOINT directory does not exist, exiting."
        exit 1
    fi
    echo " Success!"
}

download_svd_xt() {
    check_workspace

    echo -n "Checking if SVD-XT weights exist..."
    if [ ! -f $MODEL_MOUNTPOINT/stable-video-diffusion-img2vid-xt/svd_xt.safetensors ]; then
        echo " SVD-XT weights not found."
        echo -n "Checking if there's enough space for SVD-XT download..."
        FREE=$(df --output=avail -k $MODEL_MOUNTPOINT | tail -n 1)
        if [[ $FREE -lt 20000000 ]]; then
            echo -e "\nNot enough space for SVD-XT download in $MODEL_MOUNTPOINT, skipping."
            return
        fi
        echo " Success!"
        echo "Starting SVD-XT weights download..."
        wget https://huggingface.co/stabilityai/stable-video-diffusion-img2vid-xt/resolve/main/svd_xt.safetensors?download=true -P $MODEL_MOUNTPOINT/stable-video-diffusion-img2vid-xt -O svd_xt.safetensors
        wget https://huggingface.co/stabilityai/stable-video-diffusion-img2vid-xt/resolve/main/svd_xt_image_decoder.safetensors?download=true -P $MODEL_MOUNTPOINT/stable-video-diffusion-img2vid-xt -O svd_xt_image_decoder.safetensors
        echo "Successfully downloaded SVD-XT weights!"
    else
        echo " Success!"
    fi
}

# ---------------------------------------------------------------------------- #
#                               Main Program                                   #
# ---------------------------------------------------------------------------- #

execute_script "/pre_start.sh" "Running pre-start script..."

echo "Pod Started"

setup_ssh
export_env_vars
download_svd_xt
create_symlinks
start_streamlit

execute_script "/post_start.sh" "Running post-start script..."

echo "Start script(s) finished, pod is ready to use."

sleep infinity
