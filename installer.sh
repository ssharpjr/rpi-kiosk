#!/usr/bin/env bash
# RPI Kiosk Installer for Raspberry Pi

# Update the following files:
# - boot/HOSTNAME.TXT - This is the RPI's hostname.
# - boot/LINK.TXT - This is the URL that will be displayed.

# Variables - Update to your needs.
HOSTNAME_FILE="/boot/HOSTNAME.TXT"
APP_USER="runner"
APP_USER_PW="tpirunner"
MAINT_USER="pimaint"
MAINT_USER_PW="tpimaint"
REPO="rpi-kiosk"
DEBUG=0  # Set to 1 for debugging


echo -e "\nRPI Kiosk Installer\n"

# Disable console screen saver during setup
sudo setterm -blank 0


check_root() {
    if [ $(id -u) -ne 0 ]; then
        echo "Installer must be run as root."
        echo "Try 'sudo bash $0'"
        exit 1
    fi
}


copy_scripts() {
echo -e "Copying Scripts...\n"
    # Copy Scripts
    sudo cp boot/xinitrc /boot/xinitrc
    sudo cp boot/HOSTNAME.TXT /boot/HOSTNAME.TXT
    sudo cp boot/LINK.TXT /boot/LINK.TXT
}


set_pause() {
    if [ ${DEBUG} == 1 ]; then
        read -p "Press ENTER to continue"
    fi
}

set_hostname() {
    echo -e "Setting Hostname\n"
    NEW_HOSTNAME=`cat ${HOSTNAME_FILE}`
    if [ ${HOSTNAME} != ${NEW_HOSTNAME} ]; then
        echo -e "Updating Hostname\n"
        echo ${NEW_HOSTNAME} | sudo tee /etc/hostname
        sudo sed -i "s/127\.0\.1\.1\t${HOSTNAME}/127\.0\.1\.1\t${NEW_HOSTNAME}/g" \
            /etc/hosts
				# Sometimes there is a double tab?
        sudo sed -i "s/127\.0\.1\.1\t\t${HOSTNAME}/127\.0\.1\.1\t${NEW_HOSTNAME}/g" \
            /etc/hosts
    else
        echo -e "Hostname is correct\n"
    fi
}


set_locale() {
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
}


set_keyboard() {
    echo -e "Setting keyboard\n"
    sudo sed -i -e "/XKBMODEL=/s/pc105/pc104/" /etc/default/keyboard
    sudo sed -i -e "/XKBLAYOUT=/s/gb/us/" /etc/default/keyboard
    sudo sed -i -e "/XKBOPTIONS=/s/\"\"/\"terminate:ctrl_alt_bksp\"/" /etc/default/keyboard
    sudo service keyboard-setup restart
}


set_timezone() {
    echo -e "Setting Time Zone\n"
    TIMEZONE="US/Eastern"
    echo ${TIMEZONE} | sudo tee /etc/timezone
    sudo rm /etc/localtime
    sudo ln -s /usr/share/zoneinfo/US/Eastern /etc/localtime
    sudo dpkg-reconfigure -fnoninteractive tzdata
}


set_ssh() {
    echo -e "Setting SSH\n"
    sudo update-rc.d ssh enable &&
    sudo invoke-rc.d ssh start
}


set_term() {
    echo -e "Disabling Terminal Blanking\n"
    sudo sed -i "s/^exit 0/setterm -blank 0\\nexit 0/g" /etc/rc.local
}


create_user() {
    echo -e "Creating User\n"
    sudo adduser --disabled-login --gecos "" $1
    sudo usermod -G adm,dialout,cdrom,sudo,audio,video,plugdev,games,users,input,netdev,spi,i2c,gpio -a $1
}


set_user_passwords() {
    echo -e "Setting User Passwords\n"
    echo ${APP_USER}:${APP_USER_PW} | sudo chpasswd
    echo ${MAINT_USER}:${MAINT_USER_PW} | sudo chpasswd
}


set_user_sudo() {
    echo -e "Setting sudo rights\n"
    echo "$1 ALL=(ALL) NOPASSWD: ALL" | sudo tee /etc/sudoers.d/010_$1-nopasswd
    sudo chmod u-w /etc/sudoers.d/010_$1-nopasswd
}


disable_pi_user() {
    echo -e "Disabling PI User\n"
    echo "pi:0xDEADBEEF" | sudo chpasswd
    sudo usermod -L pi
}


check_network() {
    echo -e "Checking Networking\n"
    IP_ADDRESS=`hostname -I`
    if [ -z ${IP_ADDRESS} ]; then
        echo -e "No IP Address assigned\nCannot continue."
        exit 1
    fi
}


uninstall_packages() {
    echo -n "Uninstalling Packages..."
    sudo apt-get remove --purge wolfram-engine libreoffice* scratch \
         minecraft-pi sonic-pi dillo gpicview oracle-java8-jdk \
         openjdk-7-jre oracle-java7-jdk openjdk-8-jre vim-tiny -y
    echo -e " Done.\n"
}


update_packages() {
    echo -n "Updating Packages..."
    sudo apt-get update && \
    sudo apt-get upgrade -y && \
    sudo apt-get dist-upgrade -y && \
    sudo apt-get autoremove -y && \
    sudo apt-get autoclean &&
    sync
    echo -e " Done.\n"
}


install_packages() {
    echo -n "Installing Packages..."
    sudo apt-get install -y --no-install-recommends vim matchbox xserver-xorg \
                        xserver-xorg-legacy x11-xserver-utils \
                        ttf-mscorefonts-installer xinit xwit sqlite3 \
                        libnss3 chromium-browser git
    sudo apt-get autoremove -y && sudo apt-get autoclean && sync

    echo -e " Done.\n"
}


run_read_only_fs() {
    RO_SCRIPT_URL="https://raw.githubusercontent.com/adafruit/Raspberry-Pi-Installer-Scripts/master/read-only-fs.sh"
    wget ${RO_SCRIPT_URL} -O /home_ro/${MAINT_USER}/read-only-fs.sh
    sudo bash /home_ro/${MAINT_USER}/read-only-fs.sh
}


create_maint_apps() {
    echo -e "Creating Maintenance Apps\n"
    # Set Read Write on partitions
    RW_APP="remount-rw.sh"
    sudo cat <<EOF > /home/${MAINT_USER}/${RW_APP}
sudo mount -o remount,rw /
sudo mount -o remount,rw /boot
EOF
    sudo chown -R  ${MAINT_USER}:${MAINT_USER} /home/${MAINT_USER}/${RW_APP}
    sudo chmod +x /home/${MAINT_USER}/${RW_APP}

    # Set Read Only on partitions
    RO_APP="remount-ro.sh"
    sudo cat <<EOF > /home/${MAINT_USER}/${RO_APP}
sudo mount -o remount,ro /
sudo mount -o remount,ro /boot
EOF
    sudo chown -R  ${MAINT_USER}:${MAINT_USER} /home/${MAINT_USER}/${RO_APP}
    sudo chmod +x /home/${MAINT_USER}/${RO_APP}
}


setup_kiosk() {
    echo -n "Setting up Kiosk..."
    # Patch Config Files
    sudo ./update_config.py
    sudo ./update_rclocal.py
    sudo ./update_XWrapper.py

    # Create Cron Jobs (Not used with Read Only setup)
    # crontab cron/pi.cron
    # sudo crontab cron/root.cron

    # Clean up home
    rm -rf /home/${APP_USER}/.config
    rm -rf /home/${APP_USER}/.cache
    rm -rf /home/${APP_USER}/.pki
    rm -rf /home/${APP_USER}/.bash_history

    # Map /home to RAMDisk
    echo -e "\nMapping RAMDisk..."
    echo 'tmpfs /home tmpfs nodev,nosuid 0 0' | sudo tee -a /etc/fstab

    # Move /home to /home_ro. This will be copied into the new RAMDisk /home on boot.
    sudo cp -R /home/pi/${REPO} /home/${APP_USER}/${REPO}
    sudo mv /home /home_ro
    sudo mkdir -p /home  # For RAMDisk
    # sudo mkdir -p /home_ro/${APP_USER}
    # sudo mkdir -p /home_ro/${MAINT_USER}
    sudo chown -R ${APP_USER}.${APP_USER} /home_ro/${APP_USER}
    sudo chown -R ${MAINT_USER}.${MAINT_USER} /home_ro/${MAINT_USER}

    echo -e "Done.\n"
}


final_steps() {
    echo -e "\n*** Install complete. Reboot the Pi to start the kiosk. ***\n"
}

main() {
    check_root
    check_network
    copy_scripts
    set_pause
    uninstall_packages
    set_pause
    update_packages
    set_pause
    install_packages
    set_pause
    create_user ${APP_USER}
    set_pause
    create_user ${MAINT_USER}
    set_pause
    set_user_passwords
    set_pause
    set_user_sudo ${APP_USER}
    set_pause
    set_user_sudo ${MAINT_USER}
    set_pause
    create_maint_apps
    set_pause
    setup_kiosk
    set_pause
    set_keyboard
    set_pause
    set_timezone
    set_pause
    set_ssh
    set_pause
    set_term
    set_pause
    disable_pi_user
    set_pause
    set_hostname
    set_pause
    set_locale
    set_pause
    # run_read_only_fs
		final_steps
}


# Run main
main
