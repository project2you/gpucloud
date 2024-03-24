# Use Ubuntu 22.04 as the base image
FROM ubuntu:22.04

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive

# Update and install necessary packages
RUN apt-get update && \
    apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    software-properties-common

# Add Docker’s official GPG key
RUN curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -

# Set up the Docker repository
RUN add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) \
   stable"

# Install Docker
RUN apt-get update && \
    apt-get install -y docker-ce

RUN add-apt-repository ppa:flexiondotorg/nvtop && \
    apt install nvtop

# Install Python 3.10 and pip
RUN apt-get update && \
    apt-get install -y python3.10 python3-pip

# Upgrade pip
RUN pip install --upgrade pip

# Add a new user 'jovyan', add to sudo group, and set a password (optional)
RUN useradd -m jovyan && echo "jovyan:jovyan" | chpasswd && adduser jovyan sudo

# Allow 'jovyan' to use sudo without a password
RUN echo 'jovyan ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers


# Set the working directory in the container
WORKDIR /app

# Copy the requirements file into the container at /app
COPY  requirements.txt /app/
RUN pip install docker

# Install the Python dependencies
RUN pip install --ignore-installed -r requirements.txt

# Copy the rest of your application's code into the container at /app
COPY . /app

# Expose the ports that your application uses. 
# Here we expose ports 5002, 8000, and 8888 to the outside world
# App 5002
# Jupyter lab 8000
# Jupyter Notebook 8888
# tensorflow Dashboard 6006
# 
EXPOSE 5002 8000 8888 6006

# Switch to user 'jovyan'
USER jovyan

# The command to run your application (app.py) with Python
CMD ["python3", "app.py"]
