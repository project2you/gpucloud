#!/bin/bash

sudo apt update
sudo apt upgrade -y

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
echo "HOST=$new_hostname" > .env
echo "NAME=$name" > .env
echo "EMAIL=$email" >> .env
echo "PHONE=$phone" >> .env
echo "GEN_KEY=$gen_key" >> .env

# Update .env file with API endpoints and keys
echo "PROMETHEUS_API=http://63.142.245.34:9090/api/v1/targets" > .env
echo "GRAFANA_API=http://63.142.245.34:3000/api/dashboards/db" >> .env
echo "GRAFANA_API_KEY=glsa_0msDDKJvmC51jFO7YjrIl8vun9Hf94hL_1ca35609" >> .env

echo "Created or updated .env file with API configuration."

# Change current hostname
sudo hostnamectl set-hostname $new_hostname

# Update /etc/hosts
sudo sed -i "s/127.0.1.1.*/127.0.1.1\t$new_hostname/" /etc/hosts

echo "Hostname changed to $new_hostname"

#Step 2 
# Install Docker 
sudo apt-get update -y
sudo apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt-get update -y
sudo apt-get install -y docker-ce docker-ce-cli containerd.io
sudo usermod -aG docker $USER

# Change permision docker
directory="/etc/docker"

# Function to set permissions
set_permissions() {
    echo "Setting write permissions for the group on $directory"
    sudo chmod 775 $directory
    echo "Permissions have been updated."
}

# Function to add user to the docker group
add_user_to_docker_group() {
    echo "Adding $USER to the docker group..."
    sudo usermod -aG docker $USER
    echo "$USER has been added to the docker group. Please log out and back in for this to take effect."
}

# Check if the script is run as root
if [ "$(id -u)" -ne 0 ]; then
    echo "No write permission in $directory. Please run as root or request root to change permissions."
    exit 1
fi

# Check if directory exists
if [ -d "$directory" ]; then
    # Call function to set permissions
    set_permissions

    # Call function to add user to docker group
    add_user_to_docker_group
else
    echo "Directory $directory does not exist. Please check your Docker installation."
    exit 1
fi

# Step 3: Check permission to write in /etc/docker
DAEMON_FILE="/etc/docker/daemon.json"

# Check if writable permissions exist in /etc/docker
if [ ! -w "/etc/docker" ]; then
    echo "No write permission in /etc/docker. Please run as root."
    exit 1
fi

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

# Restart Docker service
echo "Restarting Docker service..."
sudo systemctl restart docker
echo "Docker service restarted."

# pull images
echo "Pulling Docker iamges..."
docker pull project2you/jupyter-nvidia-gpucloud:1.0


# กำหนดตัวแปรสำหรับทที่ตตั้งของสภาพแวดล้อมเสมือน
ENV_PATH="/opt/gpuspeed/env"

sudo apt install python3.10-venv

# ตรวจสอบและติดตตั้ง Python3 และ venv ถ้ายังไม่ได้ติดตตั้ง
if ! command -v python3 &> /dev/null; then
    echo "Python3 is not installed. Installing Python3 and its venv module..."
    sudo apt update
    sudo apt install python3 python3-venv -y
fi

# ลบสภาพแวดล้อมเสมือนเดิมถ้ามีอยยู่
if [ -d "$ENV_PATH" ]; then
    echo "Removing existing virtual environment..."
    sudo rm -rf "$ENV_PATH"
fi

#!/bin/bash

# Path to the python3.10 executable
PYTHON310_PATH=$(which python3.10)

# Check if python3.10 is installed
if [ -z "$PYTHON310_PATH" ]; then
  echo "python3.10 is not installed. Please install it before running this script."
  exit 1
fi

echo "Using python3.10 at $PYTHON310_PATH"

# Backup and create symlinks for python and python3
update_alternative() {
  local cmd=$1
  local path="/usr/bin/$cmd"

  # Check if the command already points to the correct Python version
  if [ "$(readlink -f $path)" = "$PYTHON310_PATH" ]; then
    echo "$cmd is already set to python3.10"
  else
    # Backup the existing version if it's not a symlink to python3.10
    if [ -e "$path" ] && [ "$(readlink -f $path)" != "$PYTHON310_PATH" ]; then
      sudo mv $path ${path}_backup
      echo "Backed up the existing $cmd executable to ${path}_backup"
    fi

    # Create a new symlink
    sudo ln -sf $PYTHON310_PATH $path
    echo "Linked $cmd to python3.10"
  fi
}

# Update python and python3 to point to python3.10
update_alternative "python"
update_alternative "python3"

# Verify the changes
echo "Verification:"
echo "python version: $(python --version)"
echo "python3 version: $(python3 --version)"


# สร้างสภาพแวดล้อมเสมือนใหม่
echo "Creating new virtual environment..."
python3 -m venv $ENV_PATH
echo "Virtual environment created at $ENV_PATH"

# สร้าง symlink จาก python3 ไปยัง python
if [ -f "$ENV_PATH/bin/python3" ] && [ ! -f "$ENV_PATH/bin/python" ]; then
    echo "Creating symlink from python3 to python in the virtual environment..."
    ln -s python3 $ENV_PATH/bin/python
fi

echo "Setup complete. Environment is ready."

# Set environment variable paths
ENV_PATH="/opt/gpuspeed/env"
SCRIPT_PATH="/opt/gpuspeed/app.py"
SERVICE_NAME="gpuspeed_client"
SERVICE_PATH="/etc/systemd/system/$SERVICE_NAME.service"

# Activate the environment and update pip
source $ENV_PATH/bin/activate
pip install --upgrade pip

# Download requirements.txt and install dependencies
wget -O "$ENV_PATH/requirements.txt" https://raw.githubusercontent.com/project2you/gpuspeed.net/main/client/requirements.txt
pip install -r "$ENV_PATH/requirements.txt"
pip install torch torchvision gunicorn Flask APScheduler requests
deactivate
echo "Python packages installed."

# Move the .env configuration file
if [ -f ".env" ]; then
    sudo mv .env "/opt/gpuspeed/.env"
    echo ".env file moved to /opt/gpuspeed"
fi

# Download the app.py script from GitHub
if wget -O $SCRIPT_PATH https://raw.githubusercontent.com/project2you/gpuspeed.net/main/client/app.py; then
    sudo chown $USER:$USER /opt/gpuspeed -R
    sudo chmod +x $SCRIPT_PATH
    echo "Downloaded and configured app.py."
else
    echo "Failed to download app.py from GitHub. Exiting."
    exit 1
fi

# Create and configure the systemd service file
echo "Creating systemd service file at $SERVICE_PATH"
cat <<EOF | sudo tee $SERVICE_PATH
[Unit]
Description=gpuspeed.net client Service

[Service]
ExecStart=/bin/bash -c 'source $ENV_PATH/bin/activate && cd /opt/gpuspeed && gunicorn -w 2 -b 0.0.0.0:5002 app:app'

[Install]
WantedBy=multi-user.target
EOF

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

echo "Data received: $data"
tailscale up --auth-key=$data --operator=ubuntu

#Install nvidia-gpucloud:1.0
docker pull project2you/jupyter-nvidia-gpucloud:1.0

#Install node-exporter
sudo docker pull prom/node-exporter
sudo docker run -d -p 9100:9100 --name=node_exporter prom/node-exporter

echo "Node Exporter Status:"
sudo docker ps -f name=node_exporter

echo "Installation Completed"


sudo systemctl daemon-reload
sudo systemctl restart gpuspeed_client.service


sudo journalctl -u gpuspeed_client -f
# sudo systemctl restart gpuspeed_client
# sudo systemctl stop gpuspeed_client
