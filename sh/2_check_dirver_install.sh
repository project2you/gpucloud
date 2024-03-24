#!/bin/bash

# Function to install NVIDIA driver
install_nvidia_driver() {
    sudo add-apt-repository ppa:graphics-drivers/ppa -y
    sudo apt-get update
    sudo apt-get install nvidia-driver-510 -y # You can change this to the desired driver version
    sudo reboot
}

# Function to check if NVIDIA driver is installed
is_nvidia_driver_installed() {
    if lspci | grep -i nvidia; then
        if ! nvidia-smi; then
            echo "NVIDIA driver is not installed properly."
            return 1
        else
            echo "NVIDIA driver is installed."
            return 0
        fi
    else
        echo "No NVIDIA hardware found."
        return 1
    fi
}

# Main script
if is_nvidia_driver_installed; then
    echo "NVIDIA driver is already installed."
else
    echo "Installing NVIDIA driver..."
    install_nvidia_driver
fi
