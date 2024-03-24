#!/bin/bash
# ตรวจสอบว่า nvidia-smi มีอยู่หรือไม่
if ! command -v nvidia-smi &> /dev/null
then
    echo "NVIDIA-SMI ไม่พบ. ตรวจสอบการติดตั้งไดรเวอร์ NVIDIA."
    exit 1
fi

# ทดสอบการทำงานของ nvidia-smi
if nvidia-smi
then
    echo "NVIDIA driver ทำงานปกติ."
else
    echo "มีปัญหากับ NVIDIA driver."
    exit 1
fi


################################################################################################
# ขอให้ผู้ใช้ป้อนชื่อเครื่องใหม่
read -p "Enter new hostname: " new_hostname

# ตรวจสอบว่าป้อนชื่อเครื่องใหม่หรือไม่
if [ -z "$new_hostname" ]; then
    echo "No hostname provided. Exiting."
    exit 1
fi

# เปลี่ยน hostname ปัจจุบัน
sudo hostnamectl set-hostname $new_hostname

# อัปเดต /etc/hosts
sudo sed -i "s/127.0.1.1.*/127.0.1.1\t$new_hostname/" /etc/hosts

echo "Hostname changed to $new_hostname"


#Step 2
#########################################################################################
# ตรวจสอบว่าเรามีสิทธิ์เขียนใน /etc/docker
DAEMON_FILE="/etc/docker/daemon.json"

# ตรวจสอบว่ามีสิทธิ์เขียนไฟล์ใน /etc/docker
if [ ! -w /etc/docker ]; then
    echo "ไม่มีสิทธิ์เขียนไฟล์ใน /etc/docker. กรุณารันด้วยสิทธิ์ของผู้ดูแลระบบ."
    exit 1
fi

# ตรวจสอบว่าไฟล์ daemon.json มีอยู่แล้วหรือไม่
if [ -f "$DAEMON_FILE" ]; then
    echo "ไฟล์ $DAEMON_FILE มีอยู่แล้ว."
else
    # สร้างไฟล์ daemon.json หากยังไม่มี
    echo "สร้างไฟล์ $DAEMON_FILE."
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
    echo "ไฟล์ $DAEMON_FILE ถูกสร้างเรียบร้อยแล้ว."
fi

# Restart Docker service
echo "Restarting Docker service..."
sudo systemctl restart docker
echo "Docker service restarted."


#Step 3
#########################################################################################

# ตั้งค่าตำแหน่งของ script และชื่อของ service
SCRIPT_PATH="/home/ubuntu/gpucloud/app.py"
SERVICE_NAME="gpucloud_client"
SERVICE_PATH="/etc/systemd/system/$SERVICE_NAME.service"
ENV_PATH="/home/ubuntu/gpucloud/env"


# ตรวจสอบและติดตั้ง Python3 และ venv (ถ้ายังไม่ได้ติดตั้ง)
if ! command -v python3 &> /dev/null
then
    echo "Python3 ไม่ได้ถูกติดตั้ง. กำลังติดตั้ง Python3..."
    sudo apt-get update
    sudo apt-get install python3
fi

if ! command -v pip &> /dev/null
then
    echo "pip ไม่ได้ถูกติดตั้ง. กำลังติดตั้ง pip..."
    sudo apt-get install python3-pip
fi

# สร้าง virtual environment
if [ ! -d "$ENV_PATH" ]; then
    echo "สร้าง virtual environment ที่ $ENV_PATH"
    python3 -m venv $ENV_PATH
fi

# Activate environment และ install dependencies
source $ENV_PATH/bin/activate
pip install -r /home/ubuntu/gpucloud/requirements.txt

# ติดตั้ง PyTorch และ torchvision
pip install torch torchvision

# ตรวจสอบว่า gunicorn ถูกติดตั้งหรือยัง
if ! command -v gunicorn &> /dev/null
then
    echo "Gunicorn ไม่ได้ถูกติดตั้ง. กำลังติดตั้ง Gunicorn..."
    pip install gunicorn
fi


deactivate

# สร้าง systemd service file
echo "สร้าง systemd service file ที่ $SERVICE_PATH"
cat <<EOF | sudo tee $SERVICE_PATH
[Unit]
Description=gpucloud.work client Service

[Service]
ExecStart=/bin/bash -c 'source /home/ubuntu/gpucloud/env/bin/activate && cd /home/ubuntu/gpucloud/ && gunicorn -w 4 -b 0.0.0.0:5002 app:app'


[Install]
WantedBy=multi-user.target
EOF

# Reload systemd manager configuration
sudo systemctl daemon-reload

# Enable และ start service
sudo systemctl enable $SERVICE_NAME
sudo systemctl start $SERVICE_NAME

echo "Service $SERVICE_NAME ได้ถูกสร้างและเริ่มทำงานแล้ว"


#VPN
##################################################################################################################
# ตั้งค่า URL ที่ต้องการดึงข้อมูล
URL="https://vpn.gpucloud.work/genkey"

# ใช้ curl เพื่อดึงข้อมูลจาก URL และเก็บไว้ในตัวแปร
data=$(curl -s $URL)

# ตรวจสอบว่ามีการรับข้อมูลหรือไม่
if [ -z "$data" ]; then
    echo "ไม่สามารถดึงข้อมูลจาก $URL"
    exit 1
fi

# แสดงข้อมูลที่ได้
echo "ข้อมูลที่ได้รับ: $data"

# ทำสิ่งต่างๆ ต่อด้วยข้อมูลที่ได้ (ตัวอย่างเช่น บันทึกลงไฟล์)
# echo $data > somefile.txt


#tailscale up --auth-key=$data --operator=ubuntu



##########################################################################################################

#ทำการติดตั้ง Docker และ Node Export
# Update package information
sudo apt-get update

# Install prerequisite packages
sudo apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release

# Add Docker’s official GPG key
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

# Set up the stable repository for Docker
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install the latest version of Docker Engine and containerd
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io

# Manage Docker as a non-root user (optional)
# Add your user to the docker group
sudo usermod -aG docker $USER

# Install Prometheus Node Exporter
sudo docker pull prom/node-exporter

# Run Node Exporter container
sudo docker run -d -p 9100:9100 --name=node_exporter prom/node-exporter

# Check the status of the Node Exporter
echo "Node Exporter Status:"
sudo docker ps -f name=node_exporter

echo "Install Completed"

# sudo journalctl -u gpucloud_client -f
# sudo systemctl restart gpucloud_client
# sudo systemctl stop gpucloud_client

