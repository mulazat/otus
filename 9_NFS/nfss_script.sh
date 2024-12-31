#!/bin/bash
apt install -y nfs-kernel-server
mkdir -p /srv/share/upload
chmod 777 /srv/share/upload
cat << EOF > /etc/exports
/srv/share 192.168.60.11/32(rw,sync,root_squash)
EOF
exportfs -r
echo "NFS read check - OK!" > /srv/share/upload/check_file
chmod 0777 /srv/share/upload/check_file
