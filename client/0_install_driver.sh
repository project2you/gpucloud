#!/bin/bash

# URL of the script
SCRIPT_URL="https://raw.githubusercontent.com/project2you/gpuspeed.net/main/client/1_check_driver.sh"

# Download the script using curl
curl -O $SCRIPT_URL

# Extract the filename from the URL
SCRIPT_NAME=$(basename $SCRIPT_URL)

# Make the downloaded script executable
chmod +x $SCRIPT_NAME

# Execute the script
./$SCRIPT_NAME
