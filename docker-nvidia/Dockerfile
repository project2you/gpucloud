FROM nvidia/cuda:11.6.2-base-ubuntu20.04

# ติดตตั้งทุกอย่างทที่จำเป็นสำหรับการใช้งาน Jupyter Notebook ร่วมกับ Python และ CUDA Toolkit

RUN apt-get update && apt-get install -y tzdata
ENV TZ=Asia/Bangkok
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone



RUN apt-get update && apt-get install -y locales keyboard-configuration
RUN locale-gen en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update && \
    apt-get install -y software-properties-common && \
    add-apt-repository -y ppa:deadsnakes/ppa && \
    apt-get update && \
    apt-get install -y python3.10 && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# 3. ตั้งค่า Symbolic Link
RUN ln -s /usr/bin/python3.10 /usr/bin/python


RUN apt-get update && \
    apt-get install -y python3-pip && \
    pip3 install jupyterlab && \
    apt-get install -y vim && \
    apt-get install -y wget && \
    apt-get install -y git && \
    apt-get install -y pciutils && \
    apt-get install -y lsof && \
    apt-get install -y gnupg


RUN apt-get update && apt-get install -y python3-opencv
RUN pip install opencv-python

RUN apt-get update && apt-get install ffmpeg libsm6 libxext6  -y

# ติดตั้ง PyTorch
RUN pip install torch torchvision keras

# กำหนด WORKDIR ให้เป็นตำแหน่งทที่เก็บโค้ดของ Jupyter Notebook
WORKDIR /notebooks

# สร้างโฟลเดอร์เพพื่อให้ Jupyter Notebook สามารถเข้าถึงได้
VOLUME /notebooks

#คัดลอง .
COPY samples /notebooks/samples


# เปิดพอร์ต 8999 เพพื่อให้สามารถเข้าถึง Jupyter Notebook ได้
EXPOSE 8000 8888

# กำหนดคำสสั่งทที่ให้ Docker container รัน Jupyter Notebook เมื่อเริ่มต้น
CMD ["jupyter", "lab", "--ip='*'", "--port=8000", "--no-browser", "--allow-root"]
