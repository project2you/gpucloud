FROM nvidia/cuda:12.1.0-devel-ubuntu22.04

# Set environment variables to avoid user interaction during installation
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y tzdata
ENV TZ=Asia/Bangkok
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone


RUN apt-get update && apt-get install -y locales keyboard-configuration
RUN locale-gen en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8


# Set the TOKENIZERS_PARALLELISM environment variable
ENV TOKENIZERS_PARALLELISM=false


# Install Python, pip, and necessary tools for building Python packages
RUN apt-get update && apt-get install -y \
    python3 \
    python3-pip \
    git \
    build-essential \
    libffi-dev \
    libssl-dev \
    libjpeg-dev \
    zlib1g-dev \
    curl \
    nano \
    zip \
    && rm -rf /var/lib/apt/lists/*

# ติดตั้ง ngrok
RUN curl -s https://ngrok-agent.s3.amazonaws.com/ngrok.asc | tee /etc/apt/trusted.gpg.d/ngrok.asc >/dev/null \
    && echo "deb https://ngrok-agent.s3.amazonaws.com buster main" | tee /etc/apt/sources.list.d/ngrok.list \
    && apt-get update \
    && apt-get install -y ngrok

# Upgrade pip and install wheel
RUN pip3 install --upgrade pip wheel


# Install Jupyter Notebook and other necessary Python packages for LLM
RUN pip3 install notebook \
    fire \
    tqdm \
    ipywidgets \
    datasets \
    huggingface_hub \
    accelerate \
    appdirs \
    loralib \
    bitsandbytes \
    black \
    'black[jupyter]' \
    sentencepiece \
    'gradio==3.44.4' \
    transformers>=4.28.0 \
    tensorflow \
    torch \
    keras \
    tensorboard \
    tf-keras \
    gradio \
    streamlit \
    vllm

RUN pip3 install notebook \
    ipywidgets  # Ensure ipywidgets is installed


# Install packages from GitHub
RUN pip3 install git+https://github.com/huggingface/peft.git

# กำหนด WORKDIR ให้เป็นตำแหน่งทที่เก็บโค้ดของ Jupyter Notebook
WORKDIR /notebooks

# สร้างโฟลเดอร์เพพื่อให้ Jupyter Notebook สามารถเข้าถึงได้
VOLUME /notebooks

#คัดลอง .
COPY samples /notebooks/samples

# Expose the port Jupyter Notebook will run on
EXPOSE 8888 8000

# Run Jupyter Notebook using the token and base URL from the environment variables
CMD ["sh", "-c", "jupyter lab --ip=0.0.0.0 --port=8888 --no-browser --allow-root --NotebookApp.token=${JUPYTER_TOKEN} --NotebookApp.base_url=${BASE_URL}"]
