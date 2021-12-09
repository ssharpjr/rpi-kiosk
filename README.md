# Raspberry Pi 3 Kiosk

##### Files for setting up a Raspberry Pi 3 as a ~~Read Only~~ web kiosk

This setup uses Raspbian Bullseye Lite (armhf 2021-10-30 currently), XServer, Matchbox, and Chromium.
(_The read-only feature is not longer stable_)

See the __installer.sh__ script for details.  

Run this script with sudo.  

You will need to update the following files:
  - __installer.sh__ - Check the Variables section and update credentials as needed.
  - __boot/HOSTNAME.TXT__ - This will be the name assigned to the kiosk.
  - __boot/LINK.TXT__ - This will be the URL displayed on the kiosk.

Manually copy these files to /boot after burning a fresh RPI image. They need to be in /boot on first boot.
  - __boot/wpa_supplicant.conf__ - Add your WiFi settings here. The Pi will move this file to __/etc/wpa_supplicant/__ on first boot.
