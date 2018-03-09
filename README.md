# RTD-Kiosk
##### Files for setting up a Raspberry Pi 3 with Pixel as a kiosk

### Install software
``` shell
sudo apt-get update && sudo apt-get install unclutter
```

### Edit /home/pi/.config/lxsession/LXDE-pi/autostart file
``` shell
@lxpanel --profile LXDE-pi
@pcmanfm --desktop --profile LXDE-pi
#@xscreensaver -no-splash
#@point-rpi
@xset s off
@xset -dpms
@xset s noblank
@sed -i 's/"exited_cleanly": false/"exited_cleanly": true/' ~/.config/chromium/Default/Preferences
@chromium-browser --incognito --noerrdialogs --kiosk http://your.kiosk.website
```
