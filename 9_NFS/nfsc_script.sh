#!/bin/bash
apt install -y nfs-common
echo "192.168.60.10:/srv/share/ /mnt nfs rw,sync,hard,intr 0 0" >> /etc/fstab
systemctl daemon-reload
systemctl restart remote-fs.target
cat /mnt/upload/check_file
echo "NFS write check - OK!" > /mnt/upload/check_file
cat /mnt/upload/check_file