#!/bin/bash

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
