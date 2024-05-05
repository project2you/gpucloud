#!/bin/bash

sudo apt update
sudo apt upgrade -y

sudo apt install linux-headers-$(uname -r) build-essential


# Check if the script is run as root
if [ "$(id -u)" -ne 0 ]; then
  echo "This script must be run as root" 1>&2
  exit 1
fi

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
        systemctl stop "$service_name"
        echo "Service $service_name stopped."
    else
        echo "Service $service_name is not active or does not exist."
    fi

    # Remove the directory
    echo "Removing directory $directory..."
    rm -rf "$directory"
    echo "Directory $directory has been removed."
else
    echo "Directory $directory does not exist."
fi



if [ ! -d "$directory" ]; then
    mkdir "$directory"
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


# Ensure the directory exists
if [ ! -d "/opt/gpuspeed" ]; then
    sudo mkdir -p /opt/gpuspeed
fi

# Step 3: Set up script and service name
SCRIPT_PATH="/opt/gpuspeed/app.py"
SERVICE_NAME="gpuspeed_client"
SERVICE_PATH="/etc/systemd/system/$SERVICE_NAME.service"
ENV_PATH="/opt/gpuspeed/env"

sudo mv .env "/opt/gpuspeed/"

# Download the app.py script from GitHub
echo "Downloading app.py from GitHub..."
curl -L https://raw.githubusercontent.com/project2you/gpuspeed.net/main/client/app.py -o $SCRIPT_PATH

sudo chown $USER:$USER /opt/gpuspeed -R
chmod +x $SCRIPT_PATH

# Check if the script was successfully downloaded
if [ ! -f "$SCRIPT_PATH" ]; then
    echo "Failed to download app.py from GitHub. Exiting."
    exit 1
fi

# Check and install Python3 and venv if not already installed
if ! command -v python3 &> /dev/null
then
    echo "Python3 is not installed. Installing Python3..."
    sudo apt-get update
    sudo apt-get install python3
fi

if ! command -v pip &> /dev/null
then
    echo "pip is not installed. Installing pip..."
    sudo apt-get install python3-pip
fi

# Create virtual environment
if [ ! -d "$ENV_PATH" ]; then
    echo "Creating virtual environment at $ENV_PATH"
    python3 -m venv $ENV_PATH
fi

wget https://raw.githubusercontent.com/project2you/gpuspeed.net/main/client/requirements.txt
echo "Installing Python packages..."
mv requirements.txt $ENV_PATH


# Activate environment and install dependencies
source $ENV_PATH/bin/activate
pip install -r $ENV_PATH/requirements.txt

# Install PyTorch and torchvision
pip install torch torchvision

# Check if gunicorn is installed
if ! command -v gunicorn &> /dev/null
then
    echo "Gunicorn is not installed. Installing Gunicorn..."
    pip install gunicorn
fi

sudo pip install Flask
sudo pip install APScheduler

deactivate

# Create systemd service file
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

# VPN setup
URL="https://tailscale.gpuspeed.net/genkey"
data=$(curl -s $URL)

# Check if data was retrieved
if [ -z "$data" ]; then
    echo "Could not retrieve data from $URL. Exiting."
    exit 1
fi

echo "Data received: $data"
# tailscale up --auth-key=$data --operator=ubuntu

#Install node-exporter
sudo docker pull prom/node-exporter
sudo docker run -d -p 9100:9100 --name=node_exporter prom/node-exporter

echo "Node Exporter Status:"
sudo docker ps -f name=node_exporter

echo "Installation Completed"


sudo systemctl daemon-reload
sudo systemctl restart gpuspeed_client.service


# sudo journalctl -u gpuspeed_client -f
# sudo systemctl restart gpuspeed_client
# sudo systemctl stop gpuspeed_client
