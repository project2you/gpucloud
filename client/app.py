#Web Hook tskey-webhook-kU3Sxg6CNTRL-vhVoZ16z9xKqstCWynXowKkijRFHxTXh
import torch
#from datetime import datetime , timedelta
import datetime

import random

import time
from flask import Flask, request, jsonify 

import requests
#from requests.adapters import HTTPAdapter
import socket
import speedtest # pip install speedtest-cli

from time import sleep

import docker

import socket
import fcntl
import struct

import GPUtil

from apscheduler.schedulers.background import BackgroundScheduler

import asyncio
import websockets


from numba import jit, cuda
import numpy as np
# to measure exec time
from timeit import default_timer as timer   

import cpuinfo

import aiohttp, asyncio

#import pycuda.driver as cuda
#import pycuda.autoinit

from urllib.request import urlopen

import  urllib3

import json

import schedule

from tqdm import tqdm
from colorama import Fore, init

import psutil
import platform


import urllib.request

#GPU
import GPUtil
from tabulate import tabulate

#Database
#from rethinkdb import RethinkDB
#r = RethinkDB()

#FLOP
import torchvision.models as models
import torch
from ptflops import get_model_complexity_info
import re

import requests_async as requests_asy

import aiohttp
import asyncio


from urllib.request import urlopen
from urllib.error import URLError

import requests

import time

import subprocess
import re

 
#จำนวน GPU
num_gpus=''

#ประกาศค่า ip ทที่รับค่ามาจาก Tailscale
ip =''
info_cpu_model =''
info_cpu_brand ='' 
info_cpu_name =''
info_cpu_speed = ''
info_gpu_name = ''
info_gpu_cuda = ''
info_gpu_total_memory = ''
info_gpu_flops = ''
info_gpu_speed = ''
info_uptime_days = ''
disk_free=''

list_gpus = []

from dotenv import load_dotenv
import os

# โหลดตัวแปรสภาพแวดล้อมจากไฟล์ .env
# Load environment variables from .env file
load_dotenv()

#######################################
import subprocess
from concurrent.futures import ThreadPoolExecutor

# Constants for API endpoints and keys
PROMETHEUS_API = os.environ.get('PROMETHEUS_API')  # e.g., 'http://192.168.1.41:9090/api/v1/targets'
GRAFANA_API = os.environ.get('GRAFANA_API')  # e.g., 'http://192.168.1.41:3000/api/dashboards/db'
GRAFANA_API_KEY = os.environ.get('GRAFANA_API_KEY')  # e.g., 'glsa_NQD7zrX3CwVAa2GkAeauNXugoehsWq7A_6db1cc87'
HEADERS = {'Authorization': f'Bearer {GRAFANA_API_KEY}', 'Content-Type': 'application/json'}

# ตอนนี้คุณสามารถใช้ os.environ.get เพื่อเข้าถึงตัวแปร ใช้สำหรับ Auth VPN Server ในการรับส่งข้อมูล ระหว่าง Tail - Client
AUTH_SERVER_KEY = os.environ.get('AUTH_SERVER_KEY')

#For python docker sdk
container_id =''
container_name = "gpucloud"  # ชื่อ container ที่คุณต้องการตรวจสอบและรัน

import logging

# Setup basic configuration for logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')


app = Flask(__name__)

#################################################################################################

def get_hostname():
    """Retrieve the hostname of the current machine."""
    return socket.gethostname()

def get_active_nodes():
    """Fetch the list of active nodes from Prometheus."""
    try:
        response = requests.get(PROMETHEUS_API)
        response.raise_for_status()
        targets = response.json()['data']['activeTargets']
        return [target['labels']['instance'].split(':')[0] for target in targets]
    except requests.RequestException as e:
        print(f'Error fetching targets from Prometheus: {e}')
        return []


# สมมติว่านี่คือฟังก์ชันสำหรับตรวจสอบ auth key
def verify_auth_key(key, secret_key):
    try:
        jwt.decode(key, secret_key, algorithms=["HS256"])
        return True
    except (ExpiredSignatureError, InvalidTokenError):
        return False
    

#ทดสสอบ Speed CPU / GPU
# normal function to run on cpu
def func(a):                                
    for i in range(10000000):
        a[i]+= 1     
 
# function optimized to run on gpu 
@jit(target_backend='cuda')                         
def func2(a):
    for i in range(10000000):
        a[i]+= 1
        
#ทดสอบ GPU Flops
@app.route('/flops',methods=['POST','GET'])
def flops(device='cuda:0', dtype=torch.float32):
    N = 4096  # ขนาดของเมทริกซ์, เลือกขนาดที่ใหญ่พอสำหรับการทดสอบประสิทธิภาพ

    # สร้างเมทริกซ์แบบสุ่มบน GPU
    A = torch.randn(N, N, device=device, dtype=dtype)
    B = torch.randn(N, N, device=device, dtype=dtype)

    # ทำการ Warm-up เพื่อให้ GPU พร้อมทำงาน
    for _ in range(10):
        _ = torch.matmul(A, B)

    torch.cuda.synchronize(device)  # รอให้ GPU เสร็จสิ้นงานทั้งหมด
    start_time = time.time()

    # ทำการคูณเมทริกซ์
    C = torch.matmul(A, B)

    torch.cuda.synchronize(device)  # รอให้งานคูณเมทริกซ์เสร็จสิ้น
    end_time = time.time()

    # คำนวณเวลาที่ใช้
    time_used = end_time - start_time

    # คำนวณ TFLOPS: คูณเมทริกซ์ N x N x N ครั้ง, 2 เท่าสำหรับการคูณและการบวก
    flops = (2 * N**3) / time_used
    tflops = flops / 1e12  # แปลงเป็น TFLOPS

    return round(tflops, 2)  # ปัดเศษเป็นทศนิยมสองตำแหน่ง


@app.route('/speed',methods=['POST','GET'])
def speed_test():
    init(autoreset=True)

    print(Fore.GREEN + "GETTING BEST AVAILABLE SERVERS, UPLOADING & DOWNLOADING SPEED.....")

    # initializing the SpeedTest instance
    st = speedtest.Speedtest()

    st.get_best_server()  # Get the most optimal server available
    for i in tqdm(range(10), colour="green", desc="Finding Optimal Server"):
        sleep(0.05)

    st.download()  # Get downloading speed
    for i in tqdm(range(10), colour="cyan", desc="Getting Download Speed"):
        sleep(0.05)

    st.upload()  # Get uploading Speed
    for i in tqdm(range(10), colour="red", desc="Getting Upload Speed"):
        sleep(0.05)

    # Save all these elements in a dictionary
    res_dict = st.results.dict()

    # Assign to variables with an specific format
    dwnl = str(res_dict['download'])[:2] + "." + \
        str(res_dict['download'])[2:4]


    upl = str(res_dict['upload'])[:2] + "." + str(res_dict['upload'])[2:4]

    # Display results in a nice looking table using colorama features
    print("")

    # divider - a line in the screen with a fixed width
    print(Fore.MAGENTA + "="*80)
    print(Fore.GREEN + "INTERNET SPEED TEST RESULTS:".center(80))
    print(Fore.MAGENTA + "="*80)
    print(Fore.YELLOW +
        f"Download: {dwnl}mbps({float(dwnl)*0.125:.2f}MBs) | Upload:{upl}mbps ({float(upl)*0.125:.2f}MBs) | Ping: {res_dict['ping']:.2f}ms".center(80))
    print(Fore.MAGENTA + "-"*80)
    print(Fore.CYAN +
        f"HOST:{res_dict['server']['host']} | SPONSOR:{res_dict['server']['sponsor']} | LATENCY: {res_dict['server']['latency']:.2f}".center(80))
    print(Fore.MAGENTA + "-"*80)

    speed_now = upl +'|'+ dwnl
    print(str(speed_now))
    
    return str(speed_now)

@app.route('/location',methods=['POST','GET'])
def get_location():
    response = requests.get('https://ipinfo.io/').json()
    data = []

    #ip 124.120.151.198
    #hostname ppp-124-120-151-198.revip2.asianet.co.th
    #city Chiang Mai
    #region Chiang Mai
    #country TH
    #loc 18.7904,98.9847
    #org AS17552 True Online
    #postal 50000
    #timezone Asia/Bangkok

    for key, value in response.items():
        print(key, value)
        data.append(value)

    location_now = str(data[3]) +' / '+str(data[4])
    print(location_now)

    return location_now

def get_size(bytes, suffix="B"):
    """
    Scale bytes to its proper format
    e.g:


        1253656 => '1.20MB'
        1253656678 => '1.17GB'
    """
    factor = 1024
    for unit in ["", "K", "M", "G", "T", "P"]:
        if bytes < factor:
            return f"{bytes:.2f}{unit}{suffix}"
        bytes /= factor

    data = request.args['id_user']
    data = request.args['data']
    data = request.args['gpu_model']
    data = request.args['gpu_tflops']
    data = request.args['gpu_cuda']
    data = request.args['gpu_mem']
    data = request.args['gpu_speed']
    data = request.args['cpu_model']
    data = request.args['cpu_core']
    data = request.args['cpu_speed']
    data = request.args['network_up']
    data = request.args['network_down']
    data = request.args['disk_model']
    data = request.args['disk_speed']
    data = request.args['online_duration']
    data = request.args['region']
    #data = request.args['price_rent']
    data = request.args['date_time']
    data = request.args['rent_status']
    
@app.route('/gpu',methods=['POST','GET'])
def gpu():
        #GPU
    global list_gpus , info_gpu_total_memory , info_gpu_cuda , info_gpu_name , info_gpu_speed 
    
    print("="*40, "GPU Details", "="*40)
    gpus = GPUtil.getGPUs()

    for gpu in gpus:
        # get the GPU id
        gpu_id = gpu.id
        # name of GPU
        info_gpu_name = gpu.name
        # get % percentage of GPU usage of that GPU
        gpu_load = f"{gpu.load*100}%"
        # get free memory in MB format
        gpu_free_memory = f"{gpu.memoryFree / 1024} GB"
        # get used memory
        gpu_used_memory = f"{gpu.memoryUsed / 1024} GB"
        # get total memory
        info_gpu_total_memory = f"{gpu.memoryTotal / 1024} GB"

        # get GPU temperature in Celsius
        gpu_temperature = f"{gpu.temperature} °C"
        gpu_uuid = gpu.uuid
        info_gpu_cuda = torch.version.cuda
    
        list_gpus.append((
            gpu_id, info_gpu_name, gpu_load, gpu_free_memory, gpu_used_memory,
            info_gpu_total_memory, gpu_temperature, gpu_uuid , info_gpu_cuda
        ))

    n = 10000000                           
    a = np.ones(n, dtype = np.float64)
     
    start = timer()
    func(a)
    info_cpu_speed = timer()-start 
    print("without GPU:", info_cpu_speed )    
     
    start = timer()
    func2(a)
    info_gpu_speed = timer()-start 
    #print("with GPU:", info_gpu_speed )
        
    print(tabulate(list_gpus, headers=("id", "name", "load", "free memory", "used memory", "total memory",
                                   "temperature", "uuid",'cuda')))
    return str(list_gpus)


@app.route('/cpu',methods=['POST','GET'])
def cpu():
    global info_cpu_model , info_cpu_core , info_cpu_brand , info_cpu_name , info_cpu_speed

    print("="*40, "System Information", "="*40)
    uname = platform.uname()
    print(f"System: {uname.system}")
    print(f"Node Name: {uname.node}")
    print(f"Release: {uname.release}")
    print(f"Version: {uname.version}")
    print(f"Machine: {uname.machine}")
    print(f"Processor: {uname.processor}")

    # let's print CPU information
    print("="*40, "CPU Info", "="*40)
    # number of cores
    info_cpu_core = psutil.cpu_count(logical=False) 

    print("Physical cores:", info_cpu_core)
    print("Total cores:", psutil.cpu_count(logical=True))
    # CPU frequencies
    cpufreq = psutil.cpu_freq()
    print(f"Max Frequency: {cpufreq.max:.2f}Mhz")
    print(f"Min Frequency: {cpufreq.min:.2f}Mhz")
    
    info_cpu_speed = cpufreq.current
    print(f"Current Frequency: {cpufreq.current:.2f}Mhz")

    # CPU usage
    #print("CPU Usage Per Core:")
    #for i, percentage in enumerate(psutil.cpu_percent(percpu=True, interval=1)):
    #    print(f"Core {i}: {percentage}%")
    #print(f"Total CPU Usage: {psutil.cpu_percent()}%")

    info_cpu_brand = str(cpuinfo.get_cpu_info()['brand_raw'])
  
    cpu_name = info_cpu_brand.split("with")
    
    info_cpu_name =  cpu_name[0] 
      
    '''
    r.db('whirldata').table("list_gpu").insert({'cpu_model':info_system['cpu_model'],
                                                    'cpu_core':info_system['cpu_core'],
                                                    'cpu_speed':info_system['cpu_speed'] + " Ghz",
                                                    'gpu_model':info_system['gpu_model'],
                                                    'gpu_cuda':info_system['gpu_cuda'],
                                                    'gpu_mem':info_system['gpu_mem'],
                                                    'gpu_speed':info_system['gpu_speed'],
                                                    'gpu_tflops':info_system['gpu_tflops'],
                                                    'disk_model':info_system['disk_model'],
                                                    'disk_speed':info_system['disk_speed'],
                                                    'region':info_system['region'],
                                                    'network_up':info_system['network_up'] + ' Mbps',
                                                    'network_down':info_system['network_down'] + ' Mbps',
                                                    'ip':info_system['ip'],
                                                    'online_duration':info_system['online_duration'],
                                                    'price_rent': '0',
                                                    'id_user':'user_0001',
                                                    'rent_status':'0',
                                                    'time_rents':'0',
                                                    'timestamp':str(timestamp)
                                                    }).run(conn)
    '''
    #print(info_system['cpu_model'])
    print(info_cpu_name)
    print(info_cpu_core)
    print(info_cpu_speed)
        
    return info_cpu_name


@app.route('/ram',methods=['POST','GET'])
def ram():
    global info_ram_total 
    try:
        ram_info = psutil.virtual_memory()
        toal_ram = f"{ram_info.total / 1024 / 1024 / 1024:.2f}"
        
        print(f"Total: {ram_info.total / 1024 / 1024 / 1024:.2f} GB")
        print(f"Available: {ram_info.available / 1024 / 1024 / 1024:.2f} GB")
        print(f"Used: {ram_info.used / 1024 / 1024 / 1024:.2f} GB")
        print(f"Percentage usage: {ram_info.percent}%")
        
        info_ram_total = ram_info.available / 1024 / 1024 / 1024 
        info_ram_total = f"{info_ram_total:.2f} GB" 
        info_ram_total = f"{toal_ram}/{info_ram_total}" #คิดจากยอดทั้งหมด เช่น 16 GB เหลือ 5 GB
        
    except FileNotFoundError:
        print("Ram info not available on this system")
        
    return ram_info.total

@app.route('/hdd',methods=['POST','GET'])
def hdd():
    global disk_free
    try:
        disk_info = psutil.disk_usage("/")
        print(f"Total: {disk_info.total / 1024 / 1024 / 1024:.2f} GB")
        print(f"Used: {disk_info.used / 1024 / 1024 / 1024:.2f} GB")
        print(f"Free: {disk_info.free / 1024 / 1024 / 1024:.2f} GB")
        disk_free = f"Free: {disk_info.free / 1024 / 1024 / 1024:.2f}GB"
    except FileNotFoundError:
        print("Disk info not available on this system")

#ทดสอบความเร็ว DISK
def test_disk_speed(file_size_mb=100, file_name="test_100mb.file"):
    file_size = file_size_mb * 1024 * 1024  # แปลงเป็นไบต์
    block_size = 1024  # ขนาดของบล็อคที่ใช้เขียนแต่ละครั้ง
    data = os.urandom(block_size)

    # ทดสอบความเร็วในการเขียน
    write_start_time = time.time()
    with open(file_name, "wb") as f:
        for _ in range(int(file_size / block_size)):
            f.write(data)
    write_end_time = time.time()

    # ทดสอบความเร็วในการอ่าน
    read_start_time = time.time()
    with open(file_name, "rb") as f:
        while f.read(block_size):
            pass
    read_end_time = time.time()

    os.remove(file_name)

    write_speed = file_size_mb / (write_end_time - write_start_time)
    read_speed = file_size_mb / (read_end_time - read_start_time)

    return write_speed, read_speed

#สร้างไฟล์ 100MB สำหรับทดสอบ HDD
def create_test_file(filename, size_in_mb):
    with open(filename, 'wb') as file:
        file.write(b'\0' * size_in_mb * 1024 * 1024)

#อ่านยี่ห้อ Disk
def read_first_hdd_info():
    sys_block_path = '/sys/block/'

    # ค้นหาอุปกรณ์แรกที่ไม่ใช่ loop และ ram
    for device in os.listdir(sys_block_path):
        if 'loop' not in device and 'ram' not in device:  # จะดึงมาเฉพาะ HDD ลูกแรก เท่านั้น
            device_path = os.path.join(sys_block_path, device)
            try:
                # อ่านข้อมูลจากไฟล์โมเดล
                with open(os.path.join(device_path, 'device/model'), 'r') as f:
                    model = f.read().strip()
                return device, model
            except IOError:
                # ข้อมูลโมเดลอาจไม่มีในบางอุปกรณ์
                continue
    return None, None

#เวลาในการออนไลน์
@app.route('/uptime',methods=['POST','GET'])
def uptime():
    global info_uptime_days
    
    boot_time_timestamp = psutil.boot_time()
    current_time_timestamp = time.time()
    uptime_seconds = current_time_timestamp - boot_time_timestamp
    uptime_minutes = uptime_seconds // 60
    uptime_hours = uptime_minutes // 60
    uptime_days = uptime_hours // 24
    #uptime_str = f"{int(uptime_days)} days {int(uptime_hours % 24)} hours {int(uptime_minutes % 60)} minutes"
    uptime_str = f"{int(uptime_days)} days {int(uptime_hours % 24)} hours"
    
    info_uptime_days = uptime_str
    return {"uptime": uptime_str}

#รายละเอียดการอ่านเขียน Disk
def get_disk_io_counters():
    global info_disk_read , info_disk_write 
    io_counters = psutil.disk_io_counters()
    
    info_disk_read = io_counters.read_time
    info_disk_write = io_counters.write_time
    
    return {
        "read_count": io_counters.read_count,
        "write_count": io_counters.write_count,
        "read_bytes": io_counters.read_bytes,
        "write_bytes": io_counters.write_bytes,
        "read_time": io_counters.read_time,
        "write_time": io_counters.write_time
    }

def get_kernel_info():
    return {
        "kernel_version": os.uname().release,
        "system_name": os.uname().sysname,
        "node_name": os.uname().nodename,
        "machine": os.uname().machine
    }

def get_memory_info():
    return {
        "total_memory": psutil.virtual_memory().total / (1024.0 ** 3),
        "available_memory": psutil.virtual_memory().available / (1024.0 ** 3),
        "used_memory": psutil.virtual_memory().used / (1024.0 ** 3),
        "memory_percentage": psutil.virtual_memory().percent
    }

def get_cpu_info():
    return {
        "physical_cores": psutil.cpu_count(logical=False),
        "total_cores": psutil.cpu_count(logical=True),
        "processor_speed": psutil.cpu_freq().current,
        "cpu_usage_per_core": dict(enumerate(psutil.cpu_percent(percpu=True, interval=1))),
        "total_cpu_usage": psutil.cpu_percent(interval=1)
    }

def get_disk_info():
    partitions = psutil.disk_partitions()
    disk_info = {}
    for partition in partitions:
        partition_usage = psutil.disk_usage(partition.mountpoint)
        disk_info[partition.mountpoint] = {
            "total_space": partition_usage.total / (1024.0 ** 3),
            "used_space": partition_usage.used / (1024.0 ** 3),
            "free_space": partition_usage.free / (1024.0 ** 3),
            "usage_percentage": partition_usage.percent
        }
    return disk_info

def get_network_info():
    net_io_counters = psutil.net_io_counters()
    return {
        "bytes_sent": net_io_counters.bytes_sent,
        "bytes_recv": net_io_counters.bytes_recv
    }

def get_process_info():
    process_info = []
    for process in psutil.process_iter(['pid', 'name', 'memory_percent', 'cpu_percent']):
        try:
            process_info.append({
                "pid": process.info['pid'],
                "name": process.info['name'],
                "memory_percent": process.info['memory_percent'],
                "cpu_percent": process.info['cpu_percent']
            })
        except (psutil.NoSuchProcess, psutil.AccessDenied, psutil.ZombieProcess):
            pass
    return process_info

def get_load_average():
    load_avg_1, load_avg_5, load_avg_15 = psutil.getloadavg()
    return {
        "load_average_1": load_avg_1,
        "load_average_5": load_avg_5,
        "load_average_15": load_avg_15
    }
    
def get_ip_address(ifname):
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    try:
        return socket.inet_ntoa(fcntl.ioctl(
            s.fileno(),
            0x8915,  # SIOCGIFADDR
            struct.pack('256s', ifname[:15].encode('utf-8'))
        )[20:24])
    except IOError:
        return 'Not available'
    
@app.route('/ip',methods=['POST','GET'])
def get_ip_address(ifname):
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    try:
        return socket.inet_ntoa(fcntl.ioctl(
            s.fileno(),
            0x8915,  # SIOCGIFADDR
            struct.pack('256s', ifname[:15].encode('utf-8'))
        )[20:24])
    except IOError:
        return 'Not available'


def measure_gpu_speed(device='cuda:0'):
    N = 10**8  # ขนาดของเทนเซอร์ที่ใหญ่ขึ้น
    dtype = torch.float32
    bytes_per_number = torch.tensor([], dtype=dtype).element_size()

    # สร้างเทนเซอร์ขนาดใหญ่บน CPU
    data_cpu = torch.randn(N, dtype=dtype)
    data_size_bytes = data_cpu.nelement() * bytes_per_number
    data_size_gbits = data_size_bytes * 8 / (1024**3)  # แปลงเป็น gigabits

    # วัดเวลาการถ่ายโอนข้อมูลไป GPU และกลับมา CPU
    start_time = time.time()
    data_gpu = data_cpu.to(device)  # CPU to GPU
    # ทำการคำนวณเพิ่มเติมบน GPU หากต้องการ
    result_gpu = data_gpu * 2.0  # เพิ่มงานการคำนวณเล็กน้อย
    _ = result_gpu.to('cpu')  # GPU to CPU
    end_time = time.time()

    # คำนวณความเร็วในหน่วย Gb/s
    time_taken = end_time - start_time
    speed_gbps = data_size_gbits / time_taken

    return speed_gbps

def test_internet_speed():
    try:
        st = speedtest.Speedtest()
        st.get_best_server()
        download_speed = st.download() / 1_000_000  # Convert from bits/s to Mbits/s
        upload_speed = st.upload() / 1_000_000  # Convert from bits/s to Mbits/s

        # Formatting the speeds as strings with two decimal places
        return {"network_down": f"{download_speed:.2f}", "network_up": f"{upload_speed:.2f}"}
    except Exception as e:
        print(f"An error occurred: {e}")
        return {"network_down": None, "network_up": None}

#เริ่มต้นในส่วนของการดึงค่า Infomation ของ Client ต่าง ๆ ออกมาแสดง 
#เพื่อส่งกลับไปที่ Tail.py :5001
@app.route('/info',methods=['POST','GET'])
def info():
    global info_cpu_model , info_cpu_core , info_cpu_brand , info_cpu_name , info_cpu_speed , info_ram_total
    global info_gpu_total_memory , info_gpu_cuda , info_gpu_name , info_gpu_speed , info_gpu_flops
    global info_disk_read , info_disk_write , num_gpus
    
    # ตรวจสอบ auth key ใน header
    #auth_key = request.headers.get('Auth-Key')
    #if not verify_auth_key(auth_key):
    #    return jsonify({"error": "Unauthorized"}), 401
    
        # ดำเนินการตามปกติถ้า auth key ถูกต้อง
    if request.method == 'POST':
        # ทำอะไรสักอย่างกับข้อมูลที่รับมา
        data = request.json
        #Info
        cpu()
        hdd()
        get_disk_io_counters()
        ram()
        gpu()
        flops()
        #check_uptime = get_uptime_days_hours()
        check_uptime = get_uptime()
        
        #Call speed_test
        speeds_net = test_internet_speed()
        print(f"Download Speed: {speeds_net['network_down']} Mbps")
        print(f"Upload Speed: {speeds_net['network_up']} Mbps")
        
    
        # แทนที่ 'tailscale0' ด้วยชื่ออินเทอร์เฟสที่คุณต้องการดึงข้อมูล
        interface_name = 'tailscale0'
        ip_address = get_ip_address(interface_name)

        now = datetime.datetime.now()
        t = now.strftime("%H:%M:%S")
        timestamp = now.strftime("%Y-%m-%d %H:%M:%S")
        timestamp = str(timestamp)
        
        # สร้างไฟล์ขนาด 100MB
        create_test_file('test_100mb.file', 100)

        # ทดสอบด้วยไฟล์ 100 MB
        write_speed, read_speed = test_disk_speed()
        print(f"Disk Write Speed: {write_speed:.2f} MB/s")
        print(f"Disk Read Speed: {read_speed:.2f} MB/s")

        # เช็คยี่ห้อ Disk 
        # แสดงผลข้อมูล
        device, model = read_first_hdd_info()

        #เพิ่มเติมในส่วนของ GPU ว่ามีกี่อันในเครื่อง
        # รับรายการของ GPU ที่มี
        gpus = GPUtil.getGPUs()
        num_gpus = len(gpus)
        print(f"Number of GPUs: {num_gpus}")

        # Measure and print the GPU speed
        # วัดความเร็ว TFLOPS ของ GPU
        info_gpu_flops = flops()
        print(f"GPU flops : {info_gpu_flops} TFLOPS")

        info_gpu_speed = measure_gpu_speed()
        print(f"GPU Speed : {info_gpu_speed:.2f} GB/s")

        
        #ตัดเอาเฉพาะชชื่อเบรนของ CPU อย่างเดียว ซซึ่งบางทีจะมีคำว่า AMD Ryzen 5 4600G with Radeon Graphics
        info_system = {
            "cpu_model": f"{info_cpu_name}",
            "cpu_core": str(info_cpu_core) + ' Core',
            "cpu_speed": str(round(int(info_cpu_speed) / 1024, 2)),
            "disk_model": f"Device: {device}, Model: {model} / {disk_free}",
            "disk_speed" : f"Disk Write {write_speed:.2f} Mbp/s Read {read_speed:.2f} Mbp/s",
            "ram_mem": str(info_ram_total),
            "gpu_model": f"{num_gpus}X {info_gpu_name}",
            "gpu_cuda": str(info_gpu_cuda),
            "gpu_mem": str(info_gpu_total_memory),
            "gpu_speed": str(f"{info_gpu_speed:.2f}") +' GB/s',
            "gpu_tflops" : info_gpu_flops,
            "region": str(get_location()),
            "network_up": str(speeds_net['network_up']),
            "network_down": str(speeds_net['network_down']),
            "online_duration": str(check_uptime) ,
            "ip": str(ip_address),
            'id_user':'user_0001',
            'rent_status':'0',
            'time_rents':'0',
            "timestamp": str(timestamp),
        }
                                                            
        '''
            "price_rent": str(60)
        '''
                
        print(info_system)
        return jsonify(info_system), 200


def check_and_pull_image(image_name):
    client = docker.from_env()

    # ตรวจสอบว่ามี image นี้หรือไม่
    images = client.images.list()
    if any(image_name in tag for image in images for tag in image.tags):
        print(f"Docker image '{image_name}' พบแล้วในเครื่อง")
    else:
        print(f"Docker image '{image_name}' ไม่พบ, กำลังทำการ pull...")
        pulled_image = client.images.pull(image_name)
        print(f"Pulled: {pulled_image.tags}")


@app.route('/docker_start',methods=['POST','GET'])
def docker_start():
    global container_name
    
    # ตรวจสอบ auth key ใน header
    auth_key = request.headers.get('Auth-Key')
    if not verify_auth_key(auth_key):
        return jsonify({"error": "Unauthorized"}), 401

    # ดำเนินการตามปกติถ้า auth key ถูกต้อง
    if request.method == 'POST':
        # ทำอะไรสักอย่างกับข้อมูลที่รับมา
        info_system = request.json  # ได้ dictionary จาก JSON โดยอัตโนมัติ

        # กำหนดค่า image, port และ token
        container_name = info_system['container_name'] 
        image_name = info_system['image_name']
        port = info_system['port']
        token = info_system['token']
        base_url = info_system['base_url']

        # สร้าง client สำหรับเชื่อมต่อกับ Docker daemon
        client = docker.from_env()

        # ตรวจสอบ image จาก Docker Hub
        print("Pulling Jupyter Docker image...")
        image_name = "project2you/jupyter-nvidia-gpuspeed:1.0"

        check_and_pull_image(image_name)

        try:
            container = client.containers.get(container_name)
            print(f"Container with name '{container_name}' already exists. Removing...")
            container.remove(force=True)
            print("Container removed successfully.")
        except docker.errors.NotFound:
            print(f"No existing container with name '{container_name}'. Proceeding to run a new one.")
        except docker.errors.APIError as e:
            if '409 Client Error' in str(e) and 'is already in progress' in str(e):
                print(f"Removal of container '{container_name}' is already in progress. Retrying...")
                time.sleep(10)  # Wait for 10 seconds before retrying
                try:
                    container = client.containers.get(container_name)
                    container.remove(force=True)
                    print("Container removed successfully after retry.")
                except docker.errors.APIError as e:
                    print(f"Failed to remove container after retry: {e}")
                except docker.errors.NotFound:
                    print(f"Container '{container_name}' no longer exists.")
            else:
                print(f"An error occurred: {e}")

        # Assuming you want to run a new container after the old one has been handled
        print("Running a new container.")
        container = client.containers.run(image_name, name=container_name, detach=True)
        print(f"New container '{container_name}' started.")

        port_mapping = {'8888/tcp': port}
        
        # กำหนดค่า Command สำหรับ Jupyter Notebook
        command = [
            "jupyter", "lab",
            "--ip='*'", 
            "--port="+str(port), 
            "--no-browser", 
            "--allow-root", 
            "--NotebookApp.token="+str(token), 
            "--NotebookApp.base_url="+str(base_url)
        ]

        # สร้างและรัน container
        container = client.containers.run(
            image_name,
            command=command,
            ports=port_mapping,
            name=container_name,  # ตั้งชื่อ container
            runtime="nvidia",
            detach=True
        )
        
        print("รัน container....")

        # แสดงค่า container
        container_id = container.id
        print(f"Jupyter Notebook is running in container {container.id}")

        # ตรวจสอบสถานะของ container สำหรับช่วงเวลาหนึ่ง (เช่น 5 วินาที)
        time.sleep(15) # รอประมาณ 10-15 วิ ในการสร้าง Instance เพื่อให้ container ได้เริ่มการทำงาน
        logs = container.logs().decode("utf-8")

        print("Jupyter Notebook กำลังรัน")
        print(f"เข้าถึงได้ที่: http://localhost:{port}{base_url}/?token={token}")


    # หากไม่มีปัญหา, ให้ container รันต่อแบบ detach
    #container.detach()
        # Create Dictionary
    value = {
        "data": "success",
    }
 
    # Dictionary to JSON Object using dumps() method
    # Return JSON Object
    return json.dumps(value)
    
# สมมติว่ามีฟังก์ชันสำหรับตรวจสอบ auth key
def verify_auth_key(key):
    # ตรวจสอบความถูกต้องของ key ที่นี่
    return True  # ต้องเปลี่ยนเป็นตรวจสอบจริง

@app.route('/docker_stop', methods=['POST', 'GET'])
def docker_stop():
    # สมมติว่า container_id ถูกกำหนดมาจากที่อื่นในโค้ดของคุณ
    global container_name

    # สร้าง client สำหรับเชื่อมต่อกับ Docker daemon
    client = docker.from_env()
        
    # ตรวจสอบ auth key ใน header
    auth_key = request.headers.get('Auth-Key')
    if not verify_auth_key(auth_key):
        return jsonify({"error": "Unauthorized"}), 401

    # ดำเนินการตามปกติถ้า auth key ถูกต้อง
    if request.method == 'POST':
        # รับข้อมูลจาก JSON body
        info_system = request.json
        print(info_system)

    try:
        # ค้นหา container โดยใช้ชื่อ
        container = client.containers.get(container_name)

        # หยุด container หากยังทำงานอยู่
        if container.status == 'running':
            container.stop()

        # ลบ container
        container.remove()
        print(f"Container '{container_name}' has been removed.")
    except docker.errors.NotFound:
        print(f"No container found with name '{container_name}'")
    except Exception as e:
        print(f"An error occurred: {str(e)}")
        
    return jsonify({"data": "success"})


def create_full_dashboard_for_node(node):
    """Create a comprehensive dashboard for a given node."""
    dashboard_json = {
        'dashboard': {
            'id': None,
            'uid': None,
            'title': f' {node}',
            'panels': [
                {
                    'title': 'CPU Usage',
                    'type': 'graph',
                    'targets': [{'expr': f'node_cpu_seconds_total{{instance="{node}"}}', 'format': 'time_series'}],
                    'gridPos': {'x': 0, 'y': 0, 'w': 12, 'h': 6},
                    'id': 1
                },
                {
                    'title': 'Memory Usage',
                    'type': 'graph',
                    'targets': [{'expr': f'node_memory_MemAvailable_bytes{{instance="{node}"}}', 'format': 'time_series'}],
                    'gridPos': {'x': 12, 'y': 0, 'w': 12, 'h': 6},
                    'id': 2
                },
                {
                    'title': 'Hard Disk Usage',
                    'type': 'graph',
                    'targets': [{'expr': f'node_filesystem_avail_bytes{{instance="{node}"}}', 'format': 'time_series'}],
                    'gridPos': {'x': 0, 'y': 6, 'w': 12, 'h': 6},
                    'id': 3
                },
                {
                    'title': 'Network Usage',
                    'type': 'graph',
                    'targets': [{'expr': f'node_network_receive_bytes_total{{instance="{node}"}}', 'format': 'time_series'}],
                    'gridPos': {'x': 12, 'y': 6, 'w': 12, 'h': 6},
                    'id': 4
                },
                {
                    'title': 'GPU Usage',
                    'type': 'graph',
                    'targets': [{'expr': f'nvidia_gpu_duty_cycle{{instance="{node}"}}', 'format': 'time_series'}],
                    'gridPos': {'x': 0, 'y': 12, 'w': 24, 'h': 6},
                    'id': 5
                }
            ],
            'schemaVersion': 25,
            'version': 1,
            'overwrite': False
        }
    }

    try:
        response = requests.post(GRAFANA_API, headers=HEADERS, json=dashboard_json)
        response.raise_for_status()
        print(f'Successfully created dashboard for node: {node}')
    except requests.RequestException as e:
        print(f'Failed to create dashboard for node: {node}: {e}')
#จบส่วนของ Dashboard
##############################################################################################################

def dashboard():
    try:
        hostname = get_hostname()
        
        # แทนที่ 'tailscale0' ด้วยชื่ออินเทอร์เฟสที่คุณต้องการดึงข้อมูล
        interface_name = 'tailscale0'
        ip_address = get_ip_address(interface_name)
    
        create_full_dashboard_for_node( hostname + " : "+ip_address )
        print("Begin create dashboard")
    except Exception as e:
        print(f"Error in dashboard function: {e}")

#เมื่อรันโปรแกรมให้ทำการสร้าง dashboard
dashboard() 

'''
ตัวอย่าง CURL
curl -X POST http://192.168.1.45:5001/uptime \
     -H "Content-Type: application/json" \
     -H "Auth-Key: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJleHAiOjE3MTA2MDQ0OTksImlhdCI6MTcxMDUxODA5OX0.pB1lM16uGMakBhqgMNProXOXtaeiIl3SfyQmCOGLPkI" \
     -d '{"online_duration": "2", "ip": "100.124.210.22"}'
     
'''
# Create a scheduler instance
scheduler = BackgroundScheduler()

#เช็คเวลาในการออนไลน์
@app.route('/check_uptime',methods=['POST'])
def check_uptime_node():
    print("Check uptime")
    # Example functionality of check_uptime
    logging.info("Uptime and performing to server.")
    
    global info_uptime_days , AUTH_SERVER_KEY
    info_uptime_days = "Extracted from some uptime checking logic"  # Example value

    #check_uptime = get_uptime_days_hours()
    check_uptime = get_uptime()
    print(check_uptime)
    
    #Call speed_test
    speeds_net = test_internet_speed()
    print(f"Download Speed: {speeds_net['network_down']} Mbps")
    print(f"Upload Speed: {speeds_net['network_up']} Mbps")
    
    # แทนที่ 'tailscale0' ด้วยชื่ออินเทอร์เฟสที่คุณต้องการดึงข้อมูล
    interface_name = 'tailscale0'
    ip_address = get_ip_address(interface_name)
    
    now = datetime.datetime.now()
    t = now.strftime("%H:%M:%S")
    timestamp = now.strftime("%Y-%m-%d %H:%M:%S")
    timestamp = str(timestamp)

    # สร้างไฟล์ขนาด 100MB
    create_test_file('test_100mb.file', 100)

    # ทดสอบด้วยไฟล์ 100 MB
    write_speed, read_speed = test_disk_speed()
    print(f"Disk Write Speed: {write_speed:.2f} MB/s")
    print(f"Disk Read Speed: {read_speed:.2f} MB/s")

    #เพิ่มเติมในส่วนของ GPU ว่ามีกี่อันในเครื่อง
    # รับรายการของ GPU ที่มี
    gpus = GPUtil.getGPUs()
    num_gpus = len(gpus)
    print(f"Number of GPUs: {num_gpus}")

    # Measure and print the GPU speed
    # วัดความเร็ว TFLOPS ของ GPU
    info_gpu_flops = flops()
    print(f"GPU flops : {info_gpu_flops} TFLOPS")

    info_gpu_speed = measure_gpu_speed()
    print(f"GPU Speed : {info_gpu_speed:.2f} GB/s")
    
    interface_name = 'tailscale0'
    ip_address = get_ip_address(interface_name)
    url = "https://tailscale.gpuspeed.net/uptime"
    headers = {
        "Content-Type": "application/json",
        "Auth-Key": AUTH_SERVER_KEY  # Replace with your actual AUTH_KEY
    }
    
    disk_write_speed = round(write_speed, 2)
    disk_read_speed = round(read_speed, 2)

    data = {
        'online_duration' : check_uptime ,
         "ip": ip_address,
        'network_down': speeds_net['network_down'],  # สมมติว่าได้ค่า download speed 50.5 Mbps
        'network_up': speeds_net['network_up'],    # สมมติว่าได้ค่า upload speed 10.2 Mbps
        'num_gpus' : num_gpus,
        'info_gpu_flops' : info_gpu_flops,
        'disk_write_speed': disk_write_speed,
        'disk_read_speed': disk_read_speed
    }

    #ตรวจสอบว่ามีข้อมูล ครบไหม ทดสอบ Speed
    # Ensure the key 'network_down' exists and the value is not None or "None"
    if speeds_net['network_down'] not in [None, "None"]:
        try:
            response = requests.post(url, json=data, headers=headers)
            if response.status_code == 200:
                print("Success:", response.text)
            else:
                print("Failed to post data:", response.status_code)
                print(response)
                
            return response.text
        except requests.RequestException as e:
            print("Request failed:", e)
            return str(e)
    else:
        print("No valid data for 'network_down'")
        return "No valid data for 'network_down'"

# Set up logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')

# Interval in minutes for the scheduler
SCHEDULE_INTERVAL = 2

# Create a scheduler instance
scheduler = BackgroundScheduler()

def parse_uptime_output(output):
    # Regex to capture the different components of uptime
    uptime_regex = r"up\s+((\d+)\s+days?,\s+)?((\d+):(\d+)|(\d+)\s+min),.*"
    match = re.search(uptime_regex, output)
    if match:
        days = match.group(2) or "0"
        if match.group(3).find(":") > -1:
            hours, minutes = match.group(4), match.group(5)
        else:
            hours, minutes = "0", match.group(6)

        return f"{days} Days {hours}:{minutes} Hours"
    return "Could not parse uptime information."

def get_uptime():
    try:
        result = subprocess.run(["uptime"], capture_output=True, text=True, check=True)
        return parse_uptime_output(result.stdout)
    except subprocess.CalledProcessError as e:
        return f"Failed to get uptime: {str(e)}"
       
def schedule_uptime_task():
    """Schedules the uptime function to run at set intervals."""
    next_run_time = datetime.datetime.now() + datetime.timedelta(minutes=SCHEDULE_INTERVAL)
    scheduler.add_job(uptime, 'interval', minutes=SCHEDULE_INTERVAL, next_run_time=next_run_time, replace_existing=True, id='uptime_task')
    logging.info(f"Next uptime scheduled at {next_run_time.strftime('%Y-%m-%d %H:%M')}")
    
    print("Begin check_uptime_node")
    check_uptime_node()
    print("End check_uptime_node")
    
def uptime():
    """Logs current uptime and schedules the next run."""
    current_time_str = datetime.datetime.now().strftime('%Y-%m-%d %H:%M')
    logging.info(f"Uptime function running at {current_time_str}")
    uptime_info = get_uptime()
    logging.info(f"System Uptime: {uptime_info}")
    schedule_uptime_task()

def safely_remove_job(job_id):
    """Attempts to remove a scheduled job by ID."""
    from apscheduler.jobstores.base import JobLookupError
    try:
        if scheduler.get_job(job_id):
            scheduler.remove_job(job_id)
            print(f"Job {job_id} removed successfully.")
        else:
            print(f"No job with ID {job_id} found.")
    except JobLookupError as e:
        print(f"Failed to find the job {job_id}. Error: {e}")
    except Exception as e:
        print(f"An error occurred: {e}")

if __name__ == '__main__':
    scheduler.start()
    schedule_uptime_task()  # Initial scheduling
    try:
        app.run(host='0.0.0.0', port=5002, use_reloader=False)
    except (KeyboardInterrupt, SystemExit):
        scheduler.shutdown()

'''
sudo nano /etc/systemd/system/gpuspeed_client.service
sudo systemctl enable gpuspeed_client.service
sudo systemctl restart gpuspeed_client.service
sudo systemctl status gpuspeed_client.service

journalctl -u gpuspeed_client.service -f   
'''
