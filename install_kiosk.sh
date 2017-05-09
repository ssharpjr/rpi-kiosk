#!/bin/bash

# RTD Kiosk Installer for Raspberry Pi

# Install Packages
sudo apt-get update
sudo apt-get upgrade -y
sudo apt-get purge vim-tiny -y
sudo apt-get install vim matchbox x11-xserver-utils ttf-mscorefonts-installer xwit sqlite3 libnss3 chromium-browser
sudo apt-get -f install -y
sudo apt-get autoremove -y
sudo apt-get autolclean
sync

# Copy Scripts
mkdir /home/pi/scripts
cp scripts/refresh.sh /home/pi/scripts/refresh.sh
sudo cp boot/xinitrc /boot/xinitrc

# Patch Config Files
sudo ./update_config.py
sudo ./update_rclocal.py

# Create Cron Jobs
crontab cron/pi.cron
sudo crontab cron/root.cron

