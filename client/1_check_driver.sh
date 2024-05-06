#!/bin/bash
sudo apt update
sudo apt upgrade -y

sudo apt install build-essential
sudo apt install nvidia-cuda-toolkit
sudo apt install libboost-python-dev libboost-thread-dev

sudo apt install python3-dev

# Update package list
echo "Updating package list..."

# Install Python if it's not already installed
if ! command -v python3 &> /dev/null
then
    echo "Python is not installed. Installing Python..."
    sudo apt install python3 -y
else
    echo "Python is already installed."
fi

# Install pip for Python3 if it's not already installed
if ! command -v pip3 &> /dev/null
then
    echo "pip is not installed. Installing pip..."
    sudo apt install python3-pip -y
else
    echo "pip is already installed."
fi

# Optionally, create a symbolic link for 'pip' if it's not already there
if [ ! -f /usr/bin/pip ] && [ -f /usr/bin/pip3 ]; then
    echo "Creating a symbolic link for pip3 as pip..."
    sudo ln -s /usr/bin/pip3 /usr/bin/pip
fi

echo "Installation completed successfully. pip is ready to use."




# Define CUDA paths
CUDA_BIN_PATH="/usr/local/cuda/bin"
CUDA_LIB_PATH="/usr/local/cuda/lib64"

# Write to .bashrc if the lines do not already exist
if ! grep -q "export PATH=$CUDA_BIN_PATH:\$PATH" ~/.bashrc; then
    echo "export PATH=$CUDA_BIN_PATH:\$PATH" >> ~/.bashrc
    echo "Added CUDA bin path to PATH."
fi

if ! grep -q "export LD_LIBRARY_PATH=$CUDA_LIB_PATH:\$LD_LIBRARY_PATH" ~/.bashrc; then
    echo "export LD_LIBRARY_PATH=$CUDA_LIB_PATH:\$LD_LIBRARY_PATH" >> ~/.bashrc
    echo "Added CUDA lib path to LD_LIBRARY_PATH."
fi

echo "CUDA environment variables have been configured."


# ตรวจสอบว่า Nouveau driver ถูก disable หรือยัง
if lsmod | grep -q nouveau; then
    echo "Disabling Nouveau driver..."

    # เพิ่มคำสั่ง blacklist ในไฟล์ modprobe
    echo "blacklist nouveau" | sudo tee /etc/modprobe.d/blacklist-nouveau.conf
    echo "options nouveau modeset=0" | sudo tee -a /etc/modprobe.d/blacklist-nouveau.conf

    # อัปเดต initramfs
    sudo update-initramfs -u

    # รีสตาร์ทเครื่อง
    #echo "Rebooting the system..."
    #sudo reboot
fi

# ใช้คำสั่ง lspci เพื่อค้นหารายการของการ์ดจอ NVIDIA
nvidia_card_info=$(lspci | grep -i nvidia)

if [ -n "$nvidia_card_info" ]; then
    # ตัดคำเพื่อเหลือแต่ชื่อรุ่นพร้อมตัวเลข
    # ใช้ awk เพื่อแยกข้อมูล และ sed เพื่อตัดข้อความที่ไม่ต้องการออก
    nvidia_model=$(echo "$nvidia_card_info" | awk -F ': ' '{print $2}' | sed -r 's/^.*\[//' | sed -r 's/([^0-9]*[0-9]+).*/\1/')

    echo "$nvidia_model"
else
    echo "No NVIDIA card detected."
fi

echo "Detecting NVIDIA GPU..."
gpu_model=$(lspci | grep -i nvidia | awk -F ': ' '{print $2}' | sed -r 's/([^0-9]*[0-9]+).*/\1/' | head -n 1)

if [[ -z "$gpu_model" ]]; then
    echo "No NVIDIA GPU detected. Exiting..."
    exit 1
fi

#install Driver for example : 2060
# Define the URL of the NVIDIA driver
# 2060 
NVIDIA_DRIVER_URL="https://us.download.nvidia.com/XFree86/Linux-x86_64/550.78/NVIDIA-Linux-x86_64-550.78.run"

# Define the path where the driver will be downloaded
DOWNLOAD_PATH="/tmp/NVIDIA-Linux-x86_64-550.78.run"

# Download the driver using wget (install wget if it's not installed)
if ! command -v wget &> /dev/null
then
    echo "wget could not be found, installing..."
    sudo apt-get install wget -y
fi

echo "Downloading NVIDIA driver..."
wget -O "$DOWNLOAD_PATH" "$NVIDIA_DRIVER_URL"

# Change the permission to make it executable
chmod +x "$DOWNLOAD_PATH"

# Stop the display manager to prevent it from interfering with the driver installation
sudo systemctl stop lightdm.service  # This may vary depending on your display manager (e.g., gdm3, sddm)

# Run the NVIDIA driver installer
echo "Running the NVIDIA driver installer..."
sudo "$DOWNLOAD_PATH" --dkms -s

# Restart the display manager
sudo systemctl start lightdm.service  # Adjust accordingly if using a different display manager

echo "NVIDIA driver installation completed."


#install Cuda
# Function to check if CUDA is installed
check_cuda_installed() {
    # Check if nvcc, the CUDA compiler, is available
    if nvcc --version &> /dev/null; then
        echo "CUDA is already installed."
        nvcc --version # Display the version of CUDA installed
        return 0
    else
        echo "CUDA is not installed."
        return 1
    fi
}

# Function to install CUDA
install_cuda() {
    echo "Starting CUDA installation..."
    sudo apt update
    sudo apt install nvidia-cuda-toolkit -y
    echo "CUDA installation completed."
}

# Main script execution
if ! check_cuda_installed; then
    install_cuda
else
    echo "No need to install CUDA."
fi

#Cuda
wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2204/x86_64/cuda-keyring_1.1-1_all.deb
sudo dpkg -i cuda-keyring_1.1-1_all.deb
sudo apt-get update
sudo apt-get -y install cuda

# เพิ่ม GPG key และติดตั้ง nvidia-docker
curl -s -L https://nvidia.github.io/nvidia-docker/gpgkey | sudo apt-key add -
curl -s -L https://nvidia.github.io/nvidia-docker/ubuntu22.04/nvidia-docker.list > /etc/apt/sources.list.d/nvidia-docker.list
sudo apt update
sudo apt -y install nvidia-container-toolkit

# รีสตาร์ท Docker
sudo systemctl restart docker

echo "NVIDIA driver and nvidia-container-toolkit installation completed."


# ติดตั้ง nvidia-docker2
curl -s -L https://nvidia.github.io/nvidia-docker/gpgkey | sudo apt-key add -
distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
curl -s -L https://nvidia.github.io/nvidia-docker/$distribution/nvidia-docker.list | sudo tee /etc/apt/sources.list.d/nvidia-docker.list
sudo apt-get update
sudo apt-get install -y nvidia-docker2

# รีสตาร์ท Docker เพื่อใช้งานกับ NVIDIA
sudo systemctl restart docker

echo "NVIDIA driver and nvidia-docker2 installation completed."

#ติดตั้ง Nvidia Runtime
curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg \
  && curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | \
    sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
    sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list

sudo apt-get update

sudo apt-get install -y nvidia-container-toolkit

sudo chown -R $(whoami): /run/containerd/

# ตั้งค่า Docker เพื่อใช้ NVIDIA runtime เป็นค่ามาตรฐาน
sudo mkdir -p /etc/docker
echo '{"default-runtime": "nvidia", "runtimes": {"nvidia": {"path": "nvidia-container-runtime", "runtimeArgs": []}}}' | sudo tee /etc/docker/daemon.json


# Define the path to the Docker daemon configuration file
DOCKER_CONFIG="/etc/docker/daemon.json"

# Check if the Docker configuration file already exists
if [ -f "$DOCKER_CONFIG" ]; then
    echo "Docker daemon configuration file already exists."
else
    echo "Creating a new Docker daemon configuration file."
    # Create a new Docker daemon configuration file with NVIDIA runtime settings
    echo '{
  "runtimes": {
    "nvidia": {
      "path": "/usr/bin/nvidia-container-runtime",
      "runtimeArgs": []
    }
  },
  "default-runtime": "nvidia"
}' > $DOCKER_CONFIG
fi

# Restart Docker to apply changes
echo "Restarting Docker service to apply changes."
sudo systemctl restart docker

echo "Docker is configured to use the NVIDIA runtime."

# รีสตาร์ท Docker เพื่อให้การตั้งค่ามีผล
sudo systemctl restart docker

echo "Docker is now configured to use NVIDIA GPU."

echo "Waiting for few minute before Rebooting..."
sleep 3  # This will pause the script for 5 seconds

# รีสตาร์ทเครื่อง
#echo "Rebooting the system..."
#sudo reboot
    
