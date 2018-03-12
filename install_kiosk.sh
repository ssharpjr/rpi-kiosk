#!/usr/bin/env bash

# RTD Kiosk Installer for Raspberry Pi

# Install Packages
sudo apt-get update
sudo apt-get upgrade -y
sudo apt-get purge vim-tiny -y
sudo apt-get install -y vim matchbox xserver-xorg xserver-xorg-legacy \
                        x11-xserver-utils ttf-mscorefonts-installer \
                        xinit xwit sqlite3 libnss3 chromium-browser git
sudo apt-get -f install -y
sudo apt-get autoremove -y
sudo apt-get autoclean
sync


# Basic RPI Settings
# Set Keyboard
echo -e "Setting keyboard\n"
sudo sed -i -e "/XKBMODEL=/s/pc105/pc104/" /etc/default/keyboard
sudo sed -i -e "/XKBLAYOUT=/s/gb/us/" /etc/default/keyboard
sudo sed -i -e "/XKBOPTIONS=/s/\"\"/\"terminate:ctrl_alt_bksp\"/" /etc/default/keyboard
sudo service keyboard-setup restart

# Set Time Zone
echo -e "Setting Time Zone\n"
TIMEZONE="US/Eastern"
echo ${TIMEZONE} | sudo tee /etc/timezone
sudo rm /etc/localtime
sudo ln -s /usr/share/zoneinfo/US/Eastern /etc/localtime
sudo dpkg-reconfigure -fnoninteractive tzdata

# Set Locale
echo -e "Setting Locale\n"
cat <<EOF | sudo debconf-set-selections
locales   locales/locales_to_be_generated multiselect     en_US.UTF-8 UTF-8
EOF
sudo rm /etc/locale.gen
sudo dpkg-reconfigure -f noninteractive locales
sudo update-locale LANG=en_US.UTF-8
cat <<EOF | sudo debconf-set-selections
locales   locales/default_environment_locale select     en_US.UTF-8
EOF

# Copy Scripts
# mkdir /home/pi/scripts
# cp scripts/refresh.sh /home/pi/scripts/refresh.sh
sudo cp boot/xinitrc /boot/xinitrc

# Patch Config Files
sudo ./update_config.py
sudo ./update_rclocal.py
sudo ./update_XWrapper.py

# Create Cron Jobs
# crontab cron/pi.cron
# sudo crontab cron/root.cron


# Make RPI Read Only
# Map /home to a RAMDisk
echo 'tmpfs /home tmpfs nodev,nosuid 0 0' | sudo tee -a /etc/fstab

# Move /home to /home_ro. This will be copied into the new RAMDisk /home on boot.
sudo mv /home /home_ro
sudo mkdir /home

# Make the RPI Read Only using Adafruit's script
RO_SCRIPT_URL="https://raw.githubusercontent.com/adafruit/Raspberry-Pi-Installer-Scripts/master/read-only-fs.sh"
wget ${RO_SCRIPT_URL} -O /home/${MAINT_USER}/read-only-fs.sh
sudo bash /home/${MAINT_USER}/read-only-fs.sh