Домашнее задание
Практические навыки работы с ZFS

Цель:
Отработать навыки работы с созданием томов export/import и установкой параметров;

определить алгоритм с наилучшим сжатием;
определить настройки pool’a;
найти сообщение от преподавателей.
составить список команд, которыми получен результат с их выводами.

Что нужно сделать?

Определить алгоритм с наилучшим сжатием:
Определить какие алгоритмы сжатия поддерживает zfs (gzip, zle, lzjb, lz4);
создать 4 файловых системы на каждой применить свой алгоритм сжатия;
для сжатия использовать либо текстовый файл, либо группу файлов.
Определить настройки пула.
С помощью команды zfs import собрать pool ZFS.
Командами zfs определить настройки:
   
- размер хранилища;
    
- тип pool;
    
- значение recordsize;
   
- какое сжатие используется;
   
- какая контрольная сумма используется.
Работа со снапшотами:
скопировать файл из удаленной директории;
восстановить файл локально. zfs receive;
найти зашифрованное сообщение в файле secret_message.

Задача 1 - Определить алгоритм с наилучшим сжатием.

vagrant@zfs:~$ lsblk 
NAME   MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
sda      8:0    0 29,3G  0 disk 
└─sda1   8:1    0 29,3G  0 part /
sdb      8:16   0  512M  0 disk 
sdc      8:32   0  512M  0 disk 
sdd      8:48   0  512M  0 disk 
sde      8:64   0  512M  0 disk 
sdf      8:80   0  512M  0 disk 
sdg      8:96   0  512M  0 disk 
sdh      8:112  0  512M  0 disk 
sdi      8:128  0  512M  0 disk 
sr0     11:0    1   51M  0 rom  

######## Создаём 4 пула из двух дисков в режиме RAID 1: ########
root@zfs:/home/vagrant# zpool create otus1 mirror /dev/sdb /dev/sdc
root@zfs:/home/vagrant# zpool create otus1 mirror /dev/sdd /dev/sde
cannot create 'otus1': pool already exists
root@zfs:/home/vagrant# zpool create otus2 mirror /dev/sdd /dev/sde
root@zfs:/home/vagrant# zpool create otus3 mirror /dev/sdf /dev/sdg
root@zfs:/home/vagrant# zpool create otus4 mirror /dev/sdh /dev/sdi
root@zfs:/home/vagrant# zpool list
NAME    SIZE  ALLOC   FREE  CKPOINT  EXPANDSZ   FRAG    CAP  DEDUP    HEALTH  ALTROOT
otus1   480M   111K   480M        -         -     0%     0%  1.00x    ONLINE  -
otus2   480M   105K   480M        -         -     0%     0%  1.00x    ONLINE  -
otus3   480M   104K   480M        -         -     0%     0%  1.00x    ONLINE  -
otus4   480M   105K   480M        -         -     0%     0%  1.00x    ONLINE  -

root@zfs:/home/vagrant# zpool status otus1
  pool: otus1
 state: ONLINE
config:

        NAME        STATE     READ WRITE CKSUM
        otus1       ONLINE       0     0     0
          mirror-0  ONLINE       0     0     0
            sdb     ONLINE       0     0     0
            sdc     ONLINE       0     0     0

errors: No known data errors

######## Добавим разные алгоритмы сжатия в каждую файловую систему: ########

root@zfs:/home/vagrant# zfs set compression=lzjb otus1
root@zfs:/home/vagrant# zfs set compression=lz4 otus2
root@zfs:/home/vagrant# zfs set compression=gzip-9 otus3
root@zfs:/home/vagrant# zfs set compression=zle otus4
root@zfs:/home/vagrant# zfs get all | grep compression
otus1  compression           lzjb                       local
otus2  compression           lz4                        local
otus3  compression           gzip-9                     local
otus4  compression           zle                        local

######## Скачаем один и тот же текстовый файл во все пулы: ########

for i in {1..4}; do wget -P /otus$i https://gutenberg.org/cache/epub/2600/pg2600.converter.log; done
root@zfs:/home/vagrant# ls -l /otus*
/otus1:
итого 22092
-rw-r--r-- 1 root root 41107603 дек  2 11:56 pg2600.converter.log

/otus2:
итого 18004
-rw-r--r-- 1 root root 41107603 дек  2 11:56 pg2600.converter.log

/otus3:
итого 10965
-rw-r--r-- 1 root root 41107603 дек  2 11:56 pg2600.converter.log

/otus4:
итого 40173
-rw-r--r-- 1 root root 41107603 дек  2 11:56 pg2600.converter.log

Уже на этом этапе видно, что самый оптимальный метод сжатия у нас используется в пуле otus3

######## Проверим, сколько места занимает один и тот же файл в разных пулах и проверим степень сжатия файлов: ########
root@zfs:/home/vagrant# zfs list
NAME    USED  AVAIL     REFER  MOUNTPOINT
otus1  21.7M   330M     21.6M  /otus1
otus2  17.7M   334M     17.6M  /otus2
otus3  10.9M   341M     10.7M  /otus3
otus4  39.4M   313M     39.3M  /otus4

root@zfs:/home/vagrant# zfs get all | grep compressratio | grep -v ref
otus1  compressratio         1.81x                      -
otus2  compressratio         2.23x                      -
otus3  compressratio         3.65x                      -
otus4  compressratio         1.00x                      -

# Таким образом, у нас получается, что алгоритм gzip-9 самый эффективный по сжатию.

Задача 2 - Определить настройки pool’a.
####### Скачиваем архив в домашний каталог: #######
root@zfs:/home/vagrant# wget -O archive.tar.gz --no-check-certificate 'https://drive.usercontent.google.com/download?id=1MvrcEp-WgAQe57aDEzxSRalPAwbNN1Bb&export=download'
--2024-12-27 14:41:12--  https://drive.usercontent.google.com/download?id=1MvrcEp-WgAQe57aDEzxSRalPAwbNN1Bb&export=download
Распознаётся drive.usercontent.google.com (drive.usercontent.google.com)… 142.250.74.33, 2a00:1450:4010:c0b::84
Подключение к drive.usercontent.google.com (drive.usercontent.google.com)|142.250.74.33|:443... соединение установлено.
HTTP-запрос отправлен. Ожидание ответа… 200 OK
Длина: 7275140 (6,9M) [application/octet-stream]
Сохранение в: «archive.tar.gz»

archive.tar.gz                   100%[==========================================================>]   6,94M  8,97MB/s    за 0,8s    

2024-12-27 14:41:22 (8,97 MB/s) - «archive.tar.gz» сохранён [7275140/7275140]

root@zfs:/home/vagrant# tar -xzvf archive.tar.gz
zpoolexport/
zpoolexport/filea
zpoolexport/fileb
root@zfs:/home/vagrant# zpool import -d zpoolexport/
   pool: otus
     id: 6554193320433390805
  state: ONLINE
status: Some supported features are not enabled on the pool.
        (Note that they may be intentionally disabled if the
        'compatibility' property is set.)
 action: The pool can be imported using its name or numeric identifier, though
        some features will not be available without an explicit 'zpool upgrade'.
 config:

        otus                                 ONLINE
          mirror-0                           ONLINE
            /home/vagrant/zpoolexport/filea  ONLINE
            /home/vagrant/zpoolexport/fileb  ONLINE

####### Сделаем импорт данного пула к нам в ОС: #######
root@zfs:/home/vagrant# zpool import -d zpoolexport/
   pool: otus
     id: 6554193320433390805
  state: ONLINE
status: Some supported features are not enabled on the pool.
        (Note that they may be intentionally disabled if the
        'compatibility' property is set.)
 action: The pool can be imported using its name or numeric identifier, though
        some features will not be available without an explicit 'zpool upgrade'.
 config:

        otus                                 ONLINE
          mirror-0                           ONLINE
            /home/vagrant/zpoolexport/filea  ONLINE
            /home/vagrant/zpoolexport/fileb  ONLINE
root@zfs:/home/vagrant# zpool import -d zpoolexport/ otus
root@zfs:/home/vagrant# zpool status
  pool: otus
 state: ONLINE
status: Some supported and requested features are not enabled on the pool.
        The pool can still be used, but some features are unavailable.
action: Enable all features using 'zpool upgrade'. Once this is done,
        the pool may no longer be accessible by software that does not support
        the features. See zpool-features(7) for details.
config:

        NAME                                 STATE     READ WRITE CKSUM
        otus                                 ONLINE       0     0     0
          mirror-0                           ONLINE       0     0     0
            /home/vagrant/zpoolexport/filea  ONLINE       0     0     0
            /home/vagrant/zpoolexport/fileb  ONLINE       0     0     0

errors: No known data errors

  pool: otus1
 state: ONLINE
config:

        NAME        STATE     READ WRITE CKSUM
        otus1       ONLINE       0     0     0
          mirror-0  ONLINE       0     0     0
            sdb     ONLINE       0     0     0
            sdc     ONLINE       0     0     0

errors: No known data errors

  pool: otus2
 state: ONLINE
config:

        NAME        STATE     READ WRITE CKSUM
        otus2       ONLINE       0     0     0
          mirror-0  ONLINE       0     0     0
            sdd     ONLINE       0     0     0
            sde     ONLINE       0     0     0

errors: No known data errors

  pool: otus3
 state: ONLINE
config:

        NAME        STATE     READ WRITE CKSUM
        otus3       ONLINE       0     0     0
          mirror-0  ONLINE       0     0     0
            sdf     ONLINE       0     0     0
            sdg     ONLINE       0     0     0

errors: No known data errors

  pool: otus4
 state: ONLINE
config:

        NAME        STATE     READ WRITE CKSUM
        otus4       ONLINE       0     0     0
          mirror-0  ONLINE       0     0     0
            sdh     ONLINE       0     0     0
            sdi     ONLINE       0     0     0

errors: No known data errors

####### Далее нам нужно определить настройки: ####### 
# Запрос сразу всех параметров пула: zpool get all otus
root@zfs:/home/vagrant# zpool get all otus
NAME  PROPERTY                       VALUE                          SOURCE
otus  size                           480M                           -
otus  capacity                       0%                             -
otus  altroot                        -                              default
otus  health                         ONLINE                         -
otus  guid                           6554193320433390805            -
otus  version                        -                              default
otus  bootfs                         -                              default
otus  delegation                     on                             default
otus  autoreplace                    off                            default
otus  cachefile                      -                              default
otus  failmode                       wait                           default
otus  listsnapshots                  off                            default
otus  autoexpand                     off                            default
otus  dedupratio                     1.00x                          -
otus  free                           478M                           -
otus  allocated                      2.09M                          -
otus  readonly                       off                            -
otus  ashift                         0                              default
otus  comment                        -                              default
otus  expandsize                     -                              -
otus  freeing                        0                              -
otus  fragmentation                  0%                             -
otus  leaked                         0                              -
otus  multihost                      off                            default
otus  checkpoint                     -                              -
otus  load_guid                      5864353472060181640            -
otus  autotrim                       off                            default
otus  compatibility                  off                            default
otus  feature@async_destroy          enabled                        local
otus  feature@empty_bpobj            active                         local
otus  feature@lz4_compress           active                         local
otus  feature@multi_vdev_crash_dump  enabled                        local
otus  feature@spacemap_histogram     active                         local
otus  feature@enabled_txg            active                         local
otus  feature@hole_birth             active                         local
otus  feature@extensible_dataset     active                         local
otus  feature@embedded_data          active                         local
otus  feature@bookmarks              enabled                        local
otus  feature@filesystem_limits      enabled                        local
otus  feature@large_blocks           enabled                        local
otus  feature@large_dnode            enabled                        local
otus  feature@sha512                 enabled                        local
otus  feature@skein                  enabled                        local
otus  feature@edonr                  enabled                        local
otus  feature@userobj_accounting     active                         local
otus  feature@encryption             enabled                        local
otus  feature@project_quota          active                         local
otus  feature@device_removal         enabled                        local
otus  feature@obsolete_counts        enabled                        local
otus  feature@zpool_checkpoint       enabled                        local
otus  feature@spacemap_v2            active                         local
otus  feature@allocation_classes     enabled                        local
otus  feature@resilver_defer         enabled                        local
otus  feature@bookmark_v2            enabled                        local
otus  feature@redaction_bookmarks    disabled                       local
otus  feature@redacted_datasets      disabled                       local
otus  feature@bookmark_written       disabled                       local
otus  feature@log_spacemap           disabled                       local
otus  feature@livelist               disabled                       local
otus  feature@device_rebuild         disabled                       local
otus  feature@zstd_compress          disabled                       local
otus  feature@draid                  disabled                       local

# Запрос сразу всех параметром файловой системы: zfs get all otus
root@zfs:/home/vagrant# zfs get all otus
NAME  PROPERTY              VALUE                      SOURCE
otus  type                  filesystem                 -
otus  creation              Пт мая 15  7:00 2020  -
otus  used                  2.04M                      -
otus  available             350M                       -
otus  referenced            24K                        -
otus  compressratio         1.00x                      -
otus  mounted               yes                        -
otus  quota                 none                       default
otus  reservation           none                       default
otus  recordsize            128K                       local
otus  mountpoint            /otus                      default
otus  sharenfs              off                        default
otus  checksum              sha256                     local
otus  compression           zle                        local
otus  atime                 on                         default
otus  devices               on                         default
otus  exec                  on                         default
otus  setuid                on                         default
otus  readonly              off                        default
otus  zoned                 off                        default
otus  snapdir               hidden                     default
otus  aclmode               discard                    default
otus  aclinherit            restricted                 default
otus  createtxg             1                          -
otus  canmount              on                         default
otus  xattr                 on                         default
otus  copies                1                          default
otus  version               5                          -
otus  utf8only              off                        -
otus  normalization         none                       -
otus  casesensitivity       sensitive                  -
otus  vscan                 off                        default
otus  nbmand                off                        default
otus  sharesmb              off                        default
otus  refquota              none                       default
otus  refreservation        none                       default
otus  guid                  14592242904030363272       -
otus  primarycache          all                        default
otus  secondarycache        all                        default
otus  usedbysnapshots       0B                         -
otus  usedbydataset         24K                        -
otus  usedbychildren        2.01M                      -
otus  usedbyrefreservation  0B                         -
otus  logbias               latency                    default
otus  objsetid              54                         -
otus  dedup                 off                        default
otus  mlslabel              none                       default
otus  sync                  standard                   default
otus  dnodesize             legacy                     default
otus  refcompressratio      1.00x                      -
otus  written               24K                        -
otus  logicalused           1020K                      -
otus  logicalreferenced     12K                        -
otus  volmode               default                    default
otus  filesystem_limit      none                       default
otus  snapshot_limit        none                       default
otus  filesystem_count      none                       default
otus  snapshot_count        none                       default
otus  snapdev               hidden                     default
otus  acltype               off                        default
otus  context               none                       default
otus  fscontext             none                       default
otus  defcontext            none                       default
otus  rootcontext           none                       default
otus  relatime              off                        default
otus  redundant_metadata    all                        default
otus  overlay               on                         default
otus  encryption            off                        default
otus  keylocation           none                       default
otus  keyformat             none                       default
otus  pbkdf2iters           0                          default
otus  special_small_blocks  0                          default

# C помощью команды 'get' можно уточнить конкретный параметр, например:
oot@zfs:/home/vagrant# zfs get available otus
NAME  PROPERTY   VALUE  SOURCE
otus  available  350M   -
root@zfs:/home/vagrant# zfs get readonly otus
NAME  PROPERTY  VALUE   SOURCE
otus  readonly  off     default
root@zfs:/home/vagrant# zfs get recordsize otus
NAME  PROPERTY    VALUE    SOURCE
otus  recordsize  128K     local
root@zfs:/home/vagrant# zfs get compression otus
NAME  PROPERTY     VALUE           SOURCE
otus  compression  zle             local
root@zfs:/home/vagrant# zfs get checksum otus
NAME  PROPERTY  VALUE      SOURCE
otus  checksum  sha256     local

Задача 3 - Работа со снапшотом, поиск сообщения от преподавателя.

####### Скачаем файл, указанный в задании: #######
[vagrant@zfs ~]$ wget -O otus_task2.file --no-check-certificate 'https://drive.google.com/u/0/uc?id=1gH8gCL9y7Nd5Ti3IRmplZPF1XjzxeRAG&export=download'

####### Восстановим файловую систему из снапшота: #######
root@zfs:/home/vagrant# zfs receive otus/test@today < otus_task2.file

####### Далее, ищем в каталоге /otus/test файл с именем “secret_message”: #######
root@zfs:/home/vagrant# find /otus/test -name "secret_message"
/otus/test/task1/file_mess/secret_message
root@zfs:/home/vagrant# cat /otus/test/task1/file_mess/secret_message
https://github.com/sindresorhus/awesome

