#!/bin/sh
# This script can be used for preparing and cleaning up server for cloning
# Remove the cloud-init
sudo cloud-init clean --logs
sudo touch /etc/cloud/cloud-init.disabled
sudo rm -rf /etc/netplan/50-cloud-init.yaml
sudo apt purge cloud-init -y
sudo apt autoremove -y

echo Update system
apt update -y && apt upgrade -y

echo Stop rsyslog
service rsyslog stop
echo Empty log files
find /var/log/ -type f -exec cp /dev/null {} \;
echo Remove tmp files
rm -rf /tmp/*
rm -rf /var/tmp/*


# cleanup apt
sudo apt clean

# Cleanup host ssh keys 
sudo rm -f /etc/ssh/ssh_host_*

# Check for ssh keys on reboot and regenerate if neccessary
echo Create /etc/rc.local to regenerate ssh host keys if needed
sudo cat << 'EOL' > /etc/rc.local 
#!/bin/sh
if [ ! -e /etc/ssh/ssh_host_rsa_key ]; then
  dpkg-reconfigure openssh-server
  systemctl restart ssh
fi
exit 0
EOL

# make the script executable
sudo chmod +x /etc/rc.local

# VMware customization fix https://kb.vmware.com/s/article/56409
if grep -E '^#D \/tmp 1777 root root' /usr/lib/tmpfiles.d/tmp.conf
then
  echo VM tools tmp.conf customizations already exists 
else
  echo Adding VM tools tmp.conf customization
  sed -i 's/^D \/tmp 1777 root root -/#D \/tmp 1777 root root -/' /usr/lib/tmpfiles.d/tmp.conf
fi
if grep -E '^After=dbus.service' /lib/systemd/system/open-vm-tools.service
then
  echo VM tools service customization already exists 
else
  echo Adding VM tools service customization
  sed -i '/^\[Unit\]/a\After=dbus.service' /lib/systemd/system/open-vm-tools.service
fi

echo Remove unwanted MOTD detail
chmod -x /etc/update-motd.d/10-help-text
chmod -x /etc/update-motd.d/50-motd-news

# reset the machine-id (DHCP leases in 18.04 are generated based on this... not MAC...)
#echo "" | sudo tee /etc/machine-id >/dev/null
sudo truncate -s 0 /etc/machine-id

# disable swap for K8s
# sudo swapoff --all
# sudo sed -ri '/\sswap\s/s/^#?/#/' /etc/fstab

# cleanup shell history and shutdown for templating
# history -c
# history -w

# echo Clear bash history
# cp /dev/null ~/.bash_history && history -cw

# sudo shutdown -h now
