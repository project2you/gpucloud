#!/bin/bash
export DEBIAN_FRONTEND=noninteractive

sudo apt update
sudo apt upgrade -y

echo "Setting timezone to Asia/Bangkok..."
sudo timedatectl set-timezone Asia/Bangkok
echo "Timezone is set to $(timedatectl | grep 'Time zone')"

# Check if the script is run as root
if [ "$(id -u)" -ne 0 ]; then
  echo "This script must be run as root" 1>&2
  exit 1
fi


# ตั้งค่าชื่อบริการ
SERVICE_NAME="gpuspeed_client"
# ตั้งค่าไดเรกทอรีที่ต้องการลบ
DIRECTORY="/opt/gpuspeed"

# ตรวจสอบว่าสคริปต์ถูกรันด้วยสิทธิ์ root หรือไม่
if [ "$(id -u)" -ne 0 ]; then
    echo "สคริปต์นี้ต้องรันด้วยสิทธิ์ root."
    exit 1
fi

# หยุดบริการถ้ามันกำลังทำงาน
if systemctl is-active --quiet "$SERVICE_NAME"; then
    echo "หยุดบริการ $SERVICE_NAME..."
    sudo systemctl stop "$SERVICE_NAME"
    echo "บริการ $SERVICE_NAME ถูกหยุดแล้ว."
else
    echo "บริการ $SERVICE_NAME ไม่ได้ทำงาน."
fi

# ลบไดเรกทอรี
if [ -d "$DIRECTORY" ]; then
    echo "กำลังลบไดเรกทอรี $DIRECTORY..."
    sudo rm -rf "$DIRECTORY"
    echo "ไดเรกทอรี $DIRECTORY ถูกลบเรียบร้อยแล้ว."
else
    echo "ไม่พบไดเรกทอรี $DIRECTORY."
fi

# รีโหลดและปิดใช้งานบริการเพื่อไม่ให้เริ่มขึ้นอีกในการบูตครั้งต่อไป
echo "กำลังปิดใช้งานบริการ $SERVICE_NAME..."
sudo systemctl disable "$SERVICE_NAME"
sudo systemctl reset-failed "$SERVICE_NAME"
echo "บริการ $SERVICE_NAME ถูกปิดใช้งานและรีเซ็ตสถานะเรียบร้อยแล้ว."

# Create the directory in /etc
directory="/etc/gpuspeed"
service_name="gpuspeed_client"

# Check if the script is run as root
if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run as root. Please use 'sudo' or log in as root to run this script."
    exit 1
fi

# Check if the directory exists
if [ -d "$directory" ]; then
    echo "Directory $directory exists."

    # Check if the service is active and stop it
    if systemctl is-active --quiet "$service_name"; then
        echo "Service $service_name is currently active. Stopping service..."
        sudo systemctl stop "$service_name"
        echo "Service $service_name stopped."
    else
        echo "Service $service_name is not active or does not exist."
    fi

    # Remove the directory
    echo "Removing directory $directory..."
    sudo rm -rf "$directory"
    echo "Directory $directory has been removed."
else
    echo "Directory $directory does not exist."
fi


if [ ! -d "$directory" ]; then
    sudo mkdir "$directory"
    echo "Directory created at $directory"
else
    echo "Directory already exists at $directory"
fi

# Check if nvidia-smi is available
if ! command -v nvidia-smi &> /dev/null
then
    echo "NVIDIA-SMI not found. Please check NVIDIA driver installation."
    exit 1
fi

# Test the operation of nvidia-smi
if nvidia-smi
then
    echo "NVIDIA driver is operating normally."
else
    echo "There is a problem with the NVIDIA driver."
    exit 1
fi

# Clear the screen
clear

echo ""

# Display title and labels in ASCII art format
echo "   ___      ___   _   _    ___      ___    ___     ___     ___            _  _     ___    _____  "
echo "  / __|    | _ \\ | | | |  / __|    | _ \\  | __|   | __|   |   \\          | \\| |   | __|  |_   _| "
echo " | (_ |    |  _/ | |_| |  \\__ \\    |  _/  | _|    | _|    | |) |    _    | .\` |   | _|     | |   "
echo "  \\___|   _|_|_   \\___/   |___/   _|_|_   |___|   |___|   |___/   _(_)_  |_|\\_|   |___|   _|_|_  "
echo "_|\"\"\"\"\"|_| \"\"\" |_|\"\"\"\"\"|_|\"\"\"\"\"|_| \"\"\" |_|\"\"\"\"\"|_|\"\"\"\"\"|_|\"\"\"\"\"|_|\"\"\"\"\"|_|\"\"\"\"\"|_|\"\"\"\"\"|_|\"\"\"\"\"| "
echo "\`-0-0-' \`-0-0-' \`-0-0-' \`-0-0-' \`-0-0-' \`-0-0-' \`-0-0-' \`-0-0-' \`-0-0-' \`-0-0-' \`-0-0-' \`-0-0-' "

echo ""

# Top border
echo "================================================================================================"
echo "                                   Installation for Client                                     "
echo "================================================================================================"

echo ""

# Prompt user for new hostname
read -p "Enter new hostname: " new_hostname

# Check if new hostname is provided
if [ -z "$new_hostname" ]; then
    echo "No hostname provided. Exiting."
    exit 1
fi

# Prompt for user's name
read -p "Enter your name: " name

# Validate and prompt for email
while true; do
    read -p "Enter your email: " email
    if [[ "$email" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
        break
    else
        echo "Invalid email format. Please try again."
    fi
done

# Validate and prompt for phone number
while true; do
    read -p "Enter your phone number: " phone
    if [[ "$phone" =~ ^[0-9]{10}$ ]]; then
        break
    else
        echo "Invalid phone number format. Please try again."
    fi
done

# Generate a random key
gen_key=$(openssl rand -base64 32)

# Save information in .env file
# ตรวจสอบและสร้างไฟล์ .env ถ้าไม่มีอยู่
if [ ! -f ".env" ]; then
    touch .env
    echo "Created a new .env file."
fi

# ตรวจสอบสิทธิ์การเขียน
if [ -w ".env" ]; then
    echo "The .env file is writable."
else
    echo "The .env file is not writable. Checking permissions..."
    ls -l .env
    exit 1
fi

URL="https://tailscale.gpuspeed.net/genkey_client"
data=$(curl -s $URL)

# Check if data was retrieved
if [ -z "$data" ]; then
    echo "Could not retrieve data from $URL. Exiting."
    exit 1
fi

# เขียนข้อมูลและตรวจสอบผลลัพธ์
echo "HOST=$new_hostname" > .env
echo "NAME=$name" >> .env
echo "EMAIL=$email" >> .env
echo "PHONE=$phone" >> .env
echo "GEN_KEY=$gen_key" >> .env
echo "PROMETHEUS_API=https://prometheus.gpuspeed.net/api/v1/targets" >> .env
echo "GRAFANA_API=https://grafana.gpuspeed.net/api/dashboards/db" >> .env
echo "GRAFANA_API_KEY=glsa_TsnvlyJlcKpDyOnH7NDcuTVX85QJDgEA_e7eee357" >> .env
echo "AUTH_SERVER_KEY=$data" >> .env
echo "Updated .env file with new settings."

# Change current hostname
sudo hostnamectl set-hostname $new_hostname

# Update /etc/hosts
sudo sed -i "s/127.0.1.1.*/127.0.1.1\t$new_hostname/" /etc/hosts

echo "Hostname changed to $new_hostname"

#Step 2 
echo "This script will install Docker. Please provide your password if prompted."

# Step 1: Update the package repository
echo "Updating package repository..."
sudo apt-get update -y

# Step 2: Install required packages for Docker
echo "Installing required packages for Docker..."
sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common

# Step 3: Add the GPG key for the official Docker repository to the system
# Check if daemon.json already exists
if [ -f "$DAEMON_FILE" ]; then
    echo "File $DAEMON_FILE already exists."
else
    # Create daemon.json if it does not exist
    echo "Creating file $DAEMON_FILE."
    cat <<EOF | sudo tee $DAEMON_FILE > /dev/null
    {
      "debug": true,
      "runtimes": {
        "nvidia": {
          "path": "/usr/bin/nvidia-container-runtime",
          "runtimeArgs": []
        }
      }
    }
EOF
    echo "File $DAEMON_FILE created successfully."
fi

# pull images
echo "Pulling Docker iamges..."
docker pull project2you/jupyter-nvidia-gpuspeed:1.0

# กำหนดตัวแปรสำหรับทที่ตตั้งของสภาพแวดล้อมเสมือน
ENV_PATH="/opt/gpuspeed/env"

sudo apt install python3.10-venv

# ตรวจสอบและติดตตั้ง Python3 และ venv ถ้ายังไม่ได้ติดตตั้ง
# Ensure the script is run as root
if [ "$(id -u)" -ne 0 ]; then
  echo "This script must be run as root. Please use 'sudo' to run this script."
  exit 1
fi

# Add the deadsnakes PPA which contains newer releases of Python
add-apt-repository ppa:deadsnakes/ppa -y

# Update the package list
sudo apt-get update -y

#sudo apt install nvidia-cuda-toolkit -y
sudo apt install build-essential -y

#install Cuda
wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2204/x86_64/cuda-keyring_1.1-1_all.deb
sudo dpkg -i cuda-keyring_1.1-1_all.deb
sudo apt-get update -y

# Install Python 3.10 and the Python 3.10 development and venv packages
sudo apt-get install python3.10 python3.10-venv python3.10-dev -y

# Check if pip is installed for Python 3.10 and install it if it's not present
if ! command -v pip3.10 &> /dev/null; then
    apt-get install python3-pip -y
    update-alternatives --install /usr/bin/pip pip /usr/bin/pip3.10 1
fi

# Ensure pip, python point to the pip3.10, python3.10 respectively
update-alternatives --install /usr/bin/python python /usr/bin/python3.10 1
update-alternatives --install /usr/bin/pip pip /usr/bin/pip3.10 1

# Confirm the actions
echo "Python 3.10 and pip have been installed and configured."
echo "Running 'python --version' and 'pip --version' to display the versions:"
python --version
pip --version

# สร้างสภาพแวดล้อมเสมือนใหม่
# Define the environment variable paths
ENV_PATH="/opt/gpuspeed/env"
SCRIPT_PATH="/opt/gpuspeed/app.py"
SERVICE_NAME="gpuspeed_client"
SERVICE_PATH="/etc/systemd/system/$SERVICE_NAME.service"

# Create a new virtual environment
echo "Creating new virtual environment..."
python -m venv $ENV_PATH
echo "Virtual environment created at $ENV_PATH"

# Activate the environment
source /opt/gpuspeed/env/bin/activate

# Update pip to the latest version
echo "Updating pip..."
pip install --no-cache-dir  --upgrade pip

# Download the requirements.txt file and install dependencies
echo "Downloading and installing dependencies..."
wget -O "$ENV_PATH/requirements.txt" https://raw.githubusercontent.com/project2you/gpuspeed.net/main/client/requirements.txt

pip install --no-cache-dir -r"$ENV_PATH/requirements.txt"

# Install additional packages
pip install --no-cache-dir pycuda torch torchvision gunicorn Flask APScheduler requests docker speedtest-cli

echo "Python packages installed successfully."

# Move the .env configuration file
if [ -f ".env" ]; then
    sudo mv .env "/opt/gpuspeed/.env"
    echo ".env file moved to /opt/gpuspeed"
fi

# Download the app.py script from GitHub
sudo chown -R $USER:$USER /opt/gpuspeed/env

if wget -O $SCRIPT_PATH https://raw.githubusercontent.com/project2you/gpuspeed.net/main/client/app.py; then
    sudo chown $USER:$USER /opt/gpuspeed -R
    sudo chmod +x $SCRIPT_PATH
    echo "Downloaded and configured app.py."
else
    echo "Failed to download app.py from GitHub. Exiting."
    exit 1
fi

# Create and configure the systemd service file
# Define paths and service details
SERVICE_PATH="/etc/systemd/system/gpuspeed_client.service"
DIRECTORY_PATH="/opt/gpuspeed"

# Ensure the script is run with sudo to have the necessary permissions
if [ "$EUID" -ne 0 ]
  then echo "Please run as root"
  exit
fi

# Update the ownership of the directory to the user who initiated sudo
echo "Changing ownership of $DIRECTORY_PATH to $SUDO_USER..."
sudo chown -R $SUDO_USER:$SUDO_USER $DIRECTORY_PATH

# Inform about the ownership change
echo "Ownership of $DIRECTORY_PATH has been changed to $SUDO_USER."

# Create and configure the systemd service file
echo "Creating systemd service file at $SERVICE_PATH"
sudo tee $SERVICE_PATH <<EOF
[Unit]
Description=gpuspeed.net client Service
After=network.target

[Service]
Environment=ENV_PATH=/opt/gpuspeed/env
WorkingDirectory=/opt/gpuspeed
ExecStart=/bin/bash -c 'source \${ENV_PATH}/bin/activate && exec python app.py'
User=$SUDO_USER
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

echo "Systemd service file has been created and configured."

# Reload systemd manager configuration
sudo systemctl daemon-reload

# Enable and start the service
sudo systemctl enable $SERVICE_NAME
sudo systemctl start $SERVICE_NAME
echo "Service $SERVICE_NAME has been created and started."

echo "Setup complete. Environment is ready."

# VPN setup
curl -fsSL https://tailscale.com/install.sh | sh

URL="https://tailscale.gpuspeed.net/genkey"
data=$(curl -s $URL)

# Check if data was retrieved
if [ -z "$data" ]; then
    echo "Could not retrieve data from $URL. Exiting."
    exit 1
fi

echo "Restart VPN Services..."
sudo systemctl stop tailscaled
sudo systemctl start tailscaled

echo "Please waiting about authentication..."
sudo tailscale up --auth-key=$data --operator=$USER


#Install nvidia-gpuspeed:1.0
#docker pull project2you/jupyter-nvidia-gpuspeed:1.0
#docker pull prom/node-exporter

#Install node-exporter

docker run -d -p 9100:9100 --name=node_exporter prom/node-exporter

echo "Node Exporter Status:"
sudo docker ps -f name=node_exporter

echo "Installation Completed"

sudo systemctl daemon-reload  # Reload systemd manager configuration
sudo systemctl restart docker  # Restart Docker service

sudo systemctl restart gpuspeed_client.service


exit 0
