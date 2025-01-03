#!/bin/bash
#sed -i 's/http/https/' /etc/apt/sources.list
ln -s /usr/share/X11/xkb/symbols/us /usr/share/X11/xkb/symbols/all
apt-get update
awk -i inplace '/shopt -oq posix/ { sub("#","",$0); print; for(n=0; n<=6; n++) { getline ; sub("#","",$0); print} }1' /etc/bash.bashrc
apt-get install -y dkms gcc make perl linux-headers-$(uname -r)
mount /dev/sr0 /mnt -o loop
/mnt/VBoxLinuxAdditions.run 
sleep 10
exit 0
