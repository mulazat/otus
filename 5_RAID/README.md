Описание домашнего задания
1. добавить в Vagrantfile еще дисков;
2. собрать R0/R5/R10 на выбор;
3. сломать/починить raid;
4. прописать собранный рейд в конф, чтобы рейд собирался при загрузке;
5. создать GPT раздел и 5 партиций.

Решение:
1. добавить в Vagrantfile еще дисков: 
Vagrantfile
vagrant@RAID:~$ lsblk
NAME   MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
sda      8:0    0 29,3G  0 disk 
└─sda1   8:1    0 29,3G  0 part /
sdb      8:16   0  250M  0 disk 
sdc      8:32   0  250M  0 disk 
sdd      8:48   0  250M  0 disk 
sde      8:64   0  250M  0 disk 
sdf      8:80   0  250M  0 disk 
sr0     11:0    1   51M  0 rom  


2. собрать R0/R5/R10 на выбор:
vagrant@raid:~$ sudo mdadm --create --verbose /dev/md0 -l 10 -n 5 /dev/sd{b,c,d,e,f} 
mdadm: layout defaults to n2
mdadm: layout defaults to n2
mdadm: chunk size defaults to 512K
mdadm: size set to 253952K
mdadm: Defaulting to version 1.2 metadata
mdadm: array /dev/md0 started.
vagrant@raid:~$ cat /proc/mdstat
Personalities : [linear] [multipath] [raid0] [raid1] [raid6] [raid5] [raid4] [raid10] 
md0 : active raid10 sdf[4] sde[3] sdd[2] sdc[1] sdb[0]
      634880 blocks super 1.2 512K chunks 2 near-copies [5/5] [UUUUU]
      
unused devices: <none>
vagrant@raid:~$ sudo mdadm -D /dev/md0
/dev/md0:
           Version : 1.2
     Creation Time : Thu Nov 21 08:57:58 2024
        Raid Level : raid10
        Array Size : 634880 (620.00 MiB 650.12 MB)
     Used Dev Size : 253952 (248.00 MiB 260.05 MB)
      Raid Devices : 5
     Total Devices : 5
       Persistence : Superblock is persistent

       Update Time : Thu Nov 21 08:58:02 2024
             State : clean 
    Active Devices : 5
   Working Devices : 5
    Failed Devices : 0
     Spare Devices : 0

            Layout : near=2
        Chunk Size : 512K

Consistency Policy : resync

              Name : raid:0  (local to host raid)
              UUID : 685c11a7:a99c735f:0366114f:f8391bdd
            Events : 17

    Number   Major   Minor   RaidDevice State
       0       8       16        0      active sync   /dev/sdb
       1       8       32        1      active sync   /dev/sdc
       2       8       48        2      active sync   /dev/sdd
       3       8       64        3      active sync   /dev/sde
       4       8       80        4      active sync   /dev/sdf


3. сломать/починить raid
vagrant@raid:~$ sudo mdadm /dev/md0 --fail /dev/sde
mdadm: set /dev/sde faulty in /dev/md0
vagrant@raid:~$ sudo cat /proc/mdstat
Personalities : [linear] [multipath] [raid0] [raid1] [raid6] [raid5] [raid4] [raid10] 
md0 : active raid10 sdf[4] sde[3](F) sdd[2] sdc[1] sdb[0]
      634880 blocks super 1.2 512K chunks 2 near-copies [5/4] [UUU_U]
      
unused devices: <none>
vagrant@raid:~$ sudo mdadm -D /dev/md0
/dev/md0:
           Version : 1.2
     Creation Time : Thu Nov 21 08:57:58 2024
        Raid Level : raid10
        Array Size : 634880 (620.00 MiB 650.12 MB)
     Used Dev Size : 253952 (248.00 MiB 260.05 MB)
      Raid Devices : 5
     Total Devices : 5
       Persistence : Superblock is persistent

       Update Time : Thu Nov 21 09:00:18 2024
             State : clean, degraded 
    Active Devices : 4
   Working Devices : 4
    Failed Devices : 1
     Spare Devices : 0

            Layout : near=2
        Chunk Size : 512K

Consistency Policy : resync

              Name : raid:0  (local to host raid)
              UUID : 685c11a7:a99c735f:0366114f:f8391bdd
            Events : 19

    Number   Major   Minor   RaidDevice State
       0       8       16        0      active sync   /dev/sdb
       1       8       32        1      active sync   /dev/sdc
       2       8       48        2      active sync   /dev/sdd
       -       0        0        3      removed
       4       8       80        4      active sync   /dev/sdf

       3       8       64        -      faulty   /dev/sde
vagrant@raid:~$ sudo mdadm /dev/md0 --remove /dev/sde
mdadm: hot removed /dev/sde from /dev/md0
vagrant@raid:~$ sudo mdadm /dev/md0 --add /dev/sde
mdadm: added /dev/sde
vagrant@raid:~$ cat /proc/mdstat
Personalities : [linear] [multipath] [raid0] [raid1] [raid6] [raid5] [raid4] [raid10] 
md0 : active raid10 sde[5] sdf[4] sdd[2] sdc[1] sdb[0]
      634880 blocks super 1.2 512K chunks 2 near-copies [5/5] [UUUUU]
      
unused devices: <none>

4. прописать собранный рейд в конф, чтобы рейд собирался при загрузке;
vagrant@raid:~$ sudo mdadm --detail --scan --verbose
ARRAY /dev/md0 level=raid10 num-devices=5 metadata=1.2 name=raid:0 UUID=fb530aa5:5b406eb5:d90755d7:a7df7729
   devices=/dev/sdb,/dev/sdc,/dev/sdd,/dev/sde,/dev/sdf
root@raid:/home/vagrant# sudo echo "DEVICE partitions" > /etc/mdadm/mdadm.conf
root@raid:/home/vagrant# sudo mdadm --detail --scan --verbose | awk '/ARRAY/ {print}' >> /etc/mdadm/mdadm.conf
root@raid:/home/vagrant# cat /etc/mdadm/mdadm.conf
DEVICE partitions
ARRAY /dev/md0 level=raid10 num-devices=5 metadata=1.2 name=raid:0 UUID=fb530aa5:5b406eb5:d90755d7:a7df7729

5. создать GPT раздел и 5 партиций
root@raid:/home/vagrant# sudo parted -s /dev/md0 mklabel gpt
root@raid:/home/vagrant# sudo parted /dev/md0 mkpart primary ext4 0% 20%
Information: You may need to update /etc/fstab.

root@raid:/home/vagrant# sudo parted /dev/md0 mkpart primary ext4 20% 40%
Information: You may need to update /etc/fstab.

root@raid:/home/vagrant# sudo parted /dev/md0 mkpart primary ext4 40% 60% 
Information: You may need to update /etc/fstab.

root@raid:/home/vagrant# sudo parted /dev/md0 mkpart primary ext4 60% 80% 
Information: You may need to update /etc/fstab.

root@raid:/home/vagrant# sudo parted /dev/md0 mkpart primary ext4 80% 100%
Information: You may need to update /etc/fstab.

root@raid:/home/vagrant# for i in $(seq 1 5); do mkfs.ext4 /dev/md0p$i; done     
mke2fs 1.44.5 (15-Dec-2018)
Creating filesystem with 125440 1k blocks and 31360 inodes
Filesystem UUID: bab4e009-aeee-4de0-82f6-d95212deac5e
Superblock backups stored on blocks: 
        8193, 24577, 40961, 57345, 73729

Allocating group tables: done                            
Writing inode tables: done                            
Creating journal (4096 blocks): done
Writing superblocks and filesystem accounting information: done 

mke2fs 1.44.5 (15-Dec-2018)
Creating filesystem with 125440 1k blocks and 31360 inodes
Filesystem UUID: c4209953-7e8e-4cf7-a47d-6e857a34d916
Superblock backups stored on blocks: 
        8193, 24577, 40961, 57345, 73729

Allocating group tables: done                            
Writing inode tables: done                            
Creating journal (4096 blocks): done
Writing superblocks and filesystem accounting information: done 

mke2fs 1.44.5 (15-Dec-2018)
Creating filesystem with 128000 1k blocks and 32000 inodes
Filesystem UUID: 493b78e3-a112-40fa-8626-bdb6e5de10be
Superblock backups stored on blocks: 
        8193, 24577, 40961, 57345, 73729

Allocating group tables: done                            
Writing inode tables: done                            
Creating journal (4096 blocks): done
Writing superblocks and filesystem accounting information: done 

mke2fs 1.44.5 (15-Dec-2018)
Creating filesystem with 125440 1k blocks and 31360 inodes
Filesystem UUID: a205a8ba-967b-4158-b90b-6daa710b706c
Superblock backups stored on blocks: 
        8193, 24577, 40961, 57345, 73729

Allocating group tables: done                            
Writing inode tables: done                            
Creating journal (4096 blocks): done
Writing superblocks and filesystem accounting information: done 

mke2fs 1.44.5 (15-Dec-2018)
Creating filesystem with 125440 1k blocks and 31360 inodes
Filesystem UUID: 6bb13ffb-a00b-44bc-881b-2ddd05510a4a
Superblock backups stored on blocks: 
        8193, 24577, 40961, 57345, 73729

Allocating group tables: done                            
Writing inode tables: done                            
Creating journal (4096 blocks): done
Writing superblocks and filesystem accounting information: done 

root@raid:/home/vagrant# mkdir -p /raid/part{1,2,3,4,5}
root@raid:/home/vagrant# for i in $(seq 1 5); do mount /dev/md0p$i /raid/part$i; done
root@raid:/home/vagrant# lsblk
NAME      MAJ:MIN RM   SIZE RO TYPE   MOUNTPOINT
sda         8:0    0  29,3G  0 disk   
└─sda1      8:1    0  29,3G  0 part   /
sdb         8:16   0   250M  0 disk   
└─md0       9:0    0   620M  0 raid10 
  ├─md0p1 259:1    0 122,5M  0 part   /raid/part1
  ├─md0p2 259:4    0 122,5M  0 part   /raid/part2
  ├─md0p3 259:5    0   125M  0 part   /raid/part3
  ├─md0p4 259:8    0 122,5M  0 part   /raid/part4
  └─md0p5 259:9    0 122,5M  0 part   /raid/part5
sdc         8:32   0   250M  0 disk   
└─md0       9:0    0   620M  0 raid10 
  ├─md0p1 259:1    0 122,5M  0 part   /raid/part1
  ├─md0p2 259:4    0 122,5M  0 part   /raid/part2
  ├─md0p3 259:5    0   125M  0 part   /raid/part3
  ├─md0p4 259:8    0 122,5M  0 part   /raid/part4
  └─md0p5 259:9    0 122,5M  0 part   /raid/part5
sdd         8:48   0   250M  0 disk   
└─md0       9:0    0   620M  0 raid10 
  ├─md0p1 259:1    0 122,5M  0 part   /raid/part1
  ├─md0p2 259:4    0 122,5M  0 part   /raid/part2
  ├─md0p3 259:5    0   125M  0 part   /raid/part3
  ├─md0p4 259:8    0 122,5M  0 part   /raid/part4
  └─md0p5 259:9    0 122,5M  0 part   /raid/part5
sde         8:64   0   250M  0 disk   
└─md0       9:0    0   620M  0 raid10 
  ├─md0p1 259:1    0 122,5M  0 part   /raid/part1
  ├─md0p2 259:4    0 122,5M  0 part   /raid/part2
  ├─md0p3 259:5    0   125M  0 part   /raid/part3
  ├─md0p4 259:8    0 122,5M  0 part   /raid/part4
  └─md0p5 259:9    0 122,5M  0 part   /raid/part5
sdf         8:80   0   250M  0 disk   
└─md0       9:0    0   620M  0 raid10 
  ├─md0p1 259:1    0 122,5M  0 part   /raid/part1
  ├─md0p2 259:4    0 122,5M  0 part   /raid/part2
  ├─md0p3 259:5    0   125M  0 part   /raid/part3
  ├─md0p4 259:8    0 122,5M  0 part   /raid/part4
  └─md0p5 259:9    0 122,5M  0 part   /raid/part5


