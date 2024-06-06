#!/bin/bash

# Display the list of firmware versions
echo "Please select your PS4 firmware version:"
echo "a) 9.00"
echo "b) 10.00"
echo "c) 10.01"
echo "d) 11.00"

# Prompt the user for the selection
read -p "Enter your choice (a/b/c/d): " FW_CHOICE

# Set the firmware version based on the user's choice
case $FW_CHOICE in
    a)
        FW_VERSION="900"
        ;;
    b)
        FW_VERSION="1000"
        ;;
    c)
        FW_VERSION="1001"
        ;;
    d)
        FW_VERSION="1100"
        ;;
    *)
        echo "Invalid choice. Exiting."
        exit 1
        ;;
esac

# Confirm the firmware version selection
echo "You have selected firmware version $FW_VERSION. Is this correct? (y/n)"
read -p "Enter your choice: " CONFIRMATION

if [[ $CONFIRMATION != "y" ]]; then
    echo "Firmware selection not confirmed. Exiting."
    exit 1
fi

# Define the paths for the stage1 and stage2 files based on the firmware version
STAGE1_FILE="stage1/$FW_VERSION/stage1.bin"
STAGE2_FILE="stage2/$FW_VERSION/stage2.bin"

# Create the execution script with the user inputs
cat <<EOL > pppwn_script.sh
#!/bin/bash

# Define variables
FW_VERSION=$FW_VERSION
STAGE1_FILE="$STAGE1_FILE"
STAGE2_FILE="$STAGE2_FILE"

# Disable eth0
ifconfig eth0 down

# Wait a second
sleep 1

# Enable eth0
ifconfig eth0 up

# Wait a second
sleep 1

# Change to the directory containing the pppwn executable
cd /home/pico/PPPwn-Luckfox/

# Execute the pppwn command with the desired options
./pppwn --interface eth0 --fw \$FW_VERSION --stage1 "\$STAGE1_FILE" --stage2 "\$STAGE2_FILE" -a -t 5 -nw -wap 2

# Check if the pppwn command was successful
if [ \$? -eq 0 ]; then
    echo "pppwn execution completed successfully."
    systemctl stop pppwn.service
    sleep 20
    ifconfig eth0 down
else
    echo "pppwn execution failed. Exiting script."
    exit 1
fi
EOL

# Make the pppwn and script executable
chmod +x pppwn_script.sh
chmod +x pppwn

# Create the pppwn.service file
cat <<EOL > pppwn.service
[Unit]
Description=PPPwn Script Service
After=network.target

[Service]
Type=simple
ExecStart=/home/pico/PPPwn-Luckfox/pppwn_script.sh

[Install]
WantedBy=multi-user.target
EOL

# Move and enable the service file
sudo mv pppwn.service /etc/systemd/system/
sudo chmod +x /etc/systemd/system/pppwn.service
sudo systemctl enable pppwn.service

echo "install completed! Rebooting..."

sudo reboot
