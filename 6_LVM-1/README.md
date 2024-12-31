Домашнее задание
Работа с LVM

Цель:
создавать и работать с логическими томами;

Что нужно сделать?
1. уменьшить том под / до 8G
2. выделить том под /home
3. выделить том под /var (/var - сделать в mirror)
4. для /home - сделать том для снэпшотов
5. прописать монтирование в fstab (попробовать с разными опциями и разными файловыми системами на выбор)
Работа со снапшотами:
1. сгенерировать файлы в /home/
2. снять снэпшот
3. удалить часть файлов
4. восстановиться со снэпшота

vagrant@lvm:~$ sudo -s
root@lvm:/home/vagrant# lsblk
NAME   MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
sda      8:0    0 29,3G  0 disk
└─sda1   8:1    0 29,3G  0 part /
sdb      8:16   0   20G  0 disk
sdc      8:32   0    2G  0 disk
sdd      8:48   0    1G  0 disk
sde      8:64   0    1G  0 disk
sr0     11:0    1   51M  0 rom

VG еще не создан, система установлена на sda1

root@lvm:/home/vagrant# df -h
Файловая система Размер Использовано  Дост Использовано% Cмонтировано в
udev               956M            0  956M            0% /dev
tmpfs              197M         8,3M  189M            5% /run
/dev/sda1           29G         4,6G   23G           17% /
tmpfs              985M          12K  985M            1% /dev/shm
tmpfs              5,0M         8,0K  5,0M            1% /run/lock
tmpfs              197M            0  197M            0% /run/user/105
tmpfs              197M          12K  197M            1% /run/user/1001

root@lvm:/home/vagrant# pvcreate /dev/sdb
  Physical volume "/dev/sdb" successfully created.

root@lvm:/home/vagrant# vgcreate vg_root /dev/sdb
  Volume group "vg_root" successfully created

root@lvm:/home/vagrant# lvcreate -n lv_root -l +100%FREE /dev/vg_root
  Logical volume "lv_root" created.

root@lvm:/home/vagrant# mkfs.ext4 /dev/vg_root/lv_root
mke2fs 1.44.5 (15-Dec-2018)
Creating filesystem with 5241856 4k blocks and 1310720 inodes
Filesystem UUID: 71f98272-d8c2-4bc2-86be-61a8e9b2ff3c
Superblock backups stored on blocks:
        32768, 98304, 163840, 229376, 294912, 819200, 884736, 1605632, 2654208,
        4096000

Allocating group tables: done
Writing inode tables: done
Creating journal (32768 blocks): done
Writing superblocks and filesystem accounting information: done

root@lvm:/home/vagrant# mount /dev/vg_root/lv_root /mnt

root@lvm:/home/vagrant# rsync -avxHAX --progress / /mnt/
sent 5,313,117,529 bytes  received 3,453,176 bytes  51,868,982.49 bytes/sec
total size is 5,299,258,470  speedup is 1.00
root@lvm:/home/vagrant#

root@lvm:/home/vagrant# for i in /proc/ /sys/ /dev/ /run/ /boot/; \
>  do mount --bind $i /mnt/$i; done

root@lvm:/home/vagrant# chroot /mnt/

root@lvm:/# grub-mkconfig -o /boot/grub/grub.cfg
Generating grub configuration file ...
Found background image: /usr/share/images/desktop-base/desktop-grub.png
Found linux image: /boot/vmlinuz-6.1.50-1-generic
Found initrd image: /boot/initrd.img-6.1.50-1-generic
Warning: os-prober will be executed to detect other bootable partitions.
Its output will be used to detect bootable binaries on them and create new boot entries.
done

root@lvm:/# update-initramfs -u
update-initramfs: Generating /boot/initrd.img-6.1.50-1-generic

reboot

vagrant@lvm:~$ lsblk
NAME              MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
sda                 8:0    0 29,3G  0 disk
└─sda1              8:1    0 29,3G  0 part
sdb                 8:16   0   20G  0 disk
└─vg_root-lv_root 253:0    0   20G  0 lvm  /
sdc                 8:32   0    2G  0 disk
sdd                 8:48   0    1G  0 disk
sde                 8:64   0    1G  0 disk
sr0                11:0    1   51M  0 rom

Теперь нам нужно создать VG с измененным размером и вернуть на него рут. Для этого удаляем sda1 размером в 29G и создаём новый на 15G:

root@lvm:/home/vagrant# dd if=/dev/zero of=/dev/sda bs=512 count=1
1+0 записей получено
1+0 записей отправлено
512 байт скопировано, 0,0202791 s, 25,2 kB/s
root@lvm:/home/vagrant# lsblk
NAME              MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
sda                 8:0    0 29,3G  0 disk
sdb                 8:16   0   20G  0 disk
└─vg_root-lv_root 253:0    0   20G  0 lvm  /
sdc                 8:32   0    2G  0 disk
sdd                 8:48   0    1G  0 disk
sde                 8:64   0    1G  0 disk
sr0                11:0    1   51M  0 rom

root@lvm:/home/vagrant# pvcreate /dev/sda
  Physical volume "/dev/sda" successfully created.
root@lvm:/home/vagrant# vgcreate vg_alse /dev/sda
  Volume group "vg_alse" successfully created
root@lvm:/home/vagrant# lvcreate -n vg_alse/lv_alse -L 15G /dev/vg_alse
WARNING: ext4 signature detected on /dev/vg_alse/lv_alse at offset 1080. Wipe it? [y/n]: y
  Wiping ext4 signature on /dev/vg_alse/lv_alse.
  Logical volume "lv_alse" created.
root@lvm:/home/vagrant# lsblk
NAME              MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
sda                 8:0    0 29,3G  0 disk
└─vg_alse-lv_alse 253:1    0   15G  0 lvm
sdb                 8:16   0   20G  0 disk
└─vg_root-lv_root 253:0    0   20G  0 lvm  /
sdc                 8:32   0    2G  0 disk
sdd                 8:48   0    1G  0 disk
sde                 8:64   0    1G  0 disk
sr0                11:0    1   51M  0 rom

root@lvm:/home/vagrant# mkfs.ext4 /dev/vg_alse/lv_alse

root@lvm:/home/vagrant# mount /dev/vg_alse/lv_alse /mnt

root@lvm:/home/vagrant# rsync -avxHAX --progress / /mnt/
sent 5,314,599,038 bytes  received 3,453,612 bytes  52,915,946.77 bytes/sec
total size is 5,300,739,586  speedup is 1.00

root@lvm:/home/vagrant# for i in /proc/ /sys/ /dev/ /run/ /boot/; \
>  do mount --bind $i /mnt/$i; done
root@lvm:/home/vagrant# chroot /mnt/

root@lvm:/# grub-mkconfig -o /boot/grub/grub.cfg
Generating grub configuration file ...
Found background image: /usr/share/images/desktop-base/desktop-grub.png
Found linux image: /boot/vmlinuz-6.1.50-1-generic
Found initrd image: /boot/initrd.img-6.1.50-1-generic
Warning: os-prober will be executed to detect other bootable partitions.
Its output will be used to detect bootable binaries on them and create new boot entries.
done

root@lvm:/# update-initramfs -u
update-initramfs: Generating /boot/initrd.img-6.1.50-1-generic
W: Couldn't identify type of root file system for fsck hook
