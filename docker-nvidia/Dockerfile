FROM nvidia/cuda:12.1.0-devel-ubuntu22.04

# Set environment variables to avoid user interaction during installation
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Asia/Bangkok
ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US:en
ENV LC_ALL=en_US.UTF-8
ENV TOKENIZERS_PARALLELISM=false

# Update and install dependencies
RUN apt-get update && apt-get install -y \
    tzdata locales keyboard-configuration \
    python3 python3-pip git build-essential libffi-dev libssl-dev libjpeg-dev zlib1g-dev curl nano zip \
    && ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone \
    && locale-gen en_US.UTF-8 \
    && curl -s https://ngrok-agent.s3.amazonaws.com/ngrok.asc | tee /etc/apt/trusted.gpg.d/ngrok.asc >/dev/null \
    && echo "deb https://ngrok-agent.s3.amazonaws.com buster main" | tee /etc/apt/sources.list.d/ngrok.list \
    && apt-get update \
    && apt-get install -y ngrok \
    && rm -rf /var/lib/apt/lists/*

# Upgrade pip and install wheel
RUN pip3 install --upgrade pip wheel

# Install Jupyter Notebook and other necessary Python packages for LLM
RUN pip3 install notebook \
    fire tqdm ipywidgets datasets huggingface_hub accelerate appdirs loralib bitsandbytes \
    black 'black[jupyter]' sentencepiece 'gradio==3.44.4' transformers>=4.28.0 \
    tensorflow torch keras tensorboard tf-keras gradio streamlit vllm \
    && pip3 install git+https://github.com/huggingface/peft.git

# Set the working directory and create a volume for notebooks
WORKDIR /notebooks
VOLUME /notebooks

# Copy sample notebooks
COPY samples /notebooks/samples

# Expose necessary ports
EXPOSE 8888 8000

# Set permissions for the working directory
RUN chmod -R 777 /notebooks

# Run Jupyter Notebook using the token and base URL from the environment variables
CMD ["sh", "-c", "jupyter lab --ip=0.0.0.0 --port=8888 --no-browser --allow-root --NotebookApp.token=${JUPYTER_TOKEN} --NotebookApp.base_url=${BASE_URL}"]
