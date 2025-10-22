## Домашнее задание

### Практические навыки работы с ZFS
#### Задание

- Определить алгоритм с наилучшим сжатием:
- Определить какие алгоритмы сжатия поддерживает zfs (gzip, zle, lzjb, lz4); создать 4 файловых системы на каждой применить свой алгоритм сжатия; для сжатия использовать либо текстовый файл, либо группу файлов.
- Определить настройки пула.
- С помощью команды zfs import собрать pool ZFS.
- Командами zfs определить настройки:
       
    - размер хранилища;
        
    - тип pool;
        
    - значение recordsize;
       
    - какое сжатие используется;
       
    - какая контрольная сумма используется.
- Работа со снапшотами:

    - скопировать файл из удаленной директории;
    - восстановить файл локально. zfs receive;
    - найти зашифрованное сообщение в файле secret_message.

#### Отчет

##### Стенд

- Виртуальная машина с ОС `Debian 12`
- ОЗУ: 4 Гб
- ЦПУ: 2 ядра

##### Основное задание

1. Устанавливаем пакет `ZFS`

```
user@debian:~$ sudo apt install zfsutils-linux
```
2. Проверяем диски в системе

```
user@debian:~$ lsblk
NAME   MAJ:MIN RM  SIZE RO TYPE MOUNTPOINTS
sda      8:0    0   60G  0 disk
├─sda1   8:1    0   59G  0 part /
├─sda2   8:2    0    1K  0 part
└─sda5   8:5    0  975M  0 part [SWAP]
sdb      8:16   0    2G  0 disk
sdc      8:32   0    2G  0 disk
sdd      8:48   0    2G  0 disk
sde      8:64   0    2G  0 disk
sr0     11:0    1  670M  0 rom
```
3. Создаем пулы каждый по одному диску

```
user@debian:~$ sudo zpool create otus1 /dev/sdb
user@debian:~$ sudo zpool create otus2 /dev/sdc
user@debian:~$ sudo zpool create otus3 /dev/sdd
user@debian:~$ sudo zpool create otus4 /dev/sde
```
4. Проверяем информацию о созданных пулах

```
user@debian:~$ zpool list
NAME    SIZE  ALLOC   FREE  CKPOINT  EXPANDSZ   FRAG    CAP  DEDUP    HEALTH  ALTROOT
otus1  1.88G   108K  1.87G        -         -     1%     0%  1.00x    ONLINE  -
otus2  1.88G   105K  1.87G        -         -     1%     0%  1.00x    ONLINE  -
otus3  1.88G   112K  1.87G        -         -     1%     0%  1.00x    ONLINE  -
otus4  1.88G   112K  1.87G        -         -     1%     0%  1.00x    ONLINE  -
```
5. Настраиваем разные алгоритмы сжатия для пулов

```
user@debian:~$ sudo zfs set compression=lzjb otus1
user@debian:~$ sudo zfs set compression=lz4 otus2
user@debian:~$ sudo zfs set compression=gzip-9 otus3
user@debian:~$ sudo zfs set compression=zle otus4
```
6. Проверяем правильность применения настроек

```
user@debian:~$ zfs get all | grep compression
otus1  compression           lzjb                   local
otus2  compression           lz4                    local
otus3  compression           gzip-9                 local
otus4  compression           zle                    local
```
7. Скачаем файл из методички в каждый из пулов

```
user@debian:~$ for i in {1..4}; do sudo wget -P /otus$i https://gutenberg.org/cache/epub/2600/pg2600.converter.log; done
```
8. Проверяем размер файла в пулах с разным сжатием

```
user@debian:~$ ls -lh /otus*
/otus1:
total 22M
-rw-r--r-- 1 root root 40M Oct  2 10:31 pg2600.converter.log

/otus2:
total 18M
-rw-r--r-- 1 root root 40M Oct  2 10:31 pg2600.converter.log

/otus3:
total 11M
-rw-r--r-- 1 root root 40M Oct  2 10:31 pg2600.converter.log

/otus4:
total 40M
-rw-r--r-- 1 root root 40M Oct  2 10:31 pg2600.converter.log
```
```
user@debian:~$ zfs list
NAME    USED  AVAIL  REFER  MOUNTPOINT
otus1  21.7M  1.73G  21.6M  /otus1
otus2  17.7M  1.73G  17.6M  /otus2
otus3  10.8M  1.74G  10.7M  /otus3
otus4  39.4M  1.71G  39.3M  /otus4
```
```
user@debian:~$ zfs get all | grep compressratio | grep -v ref
otus1  compressratio         1.82x                  -
otus2  compressratio         2.23x                  -
otus3  compressratio         3.67x                  -
otus4  compressratio         1.00x                  -
```
`gzip-9` оказался самым эффективным, но, согласно документации, он будет самым медленным
9. Скачиваем файл из методички и разархивируем его

```
user@debian:~$ wget -O archive.tar.gz --no-check-certificate 'https://drive.usercontent.google.com/download?id=1MvrcEp-WgAQe57aDEzxSRalPAwbNN1Bb&export=download'
...
user@debian:~$ tar -xzvf archive.tar.gz
zpoolexport/
zpoolexport/filea
zpoolexport/fileb
```
10. Проверяем возможность импорта каталога в пул

```
user@debian:~$ sudo zpool import -d zpoolexport/
  pool: otus
    id: 6554193320433390805
 state: ONLINE
status: Some supported features are not enabled on the pool.
        (Note that they may be intentionally disabled if the
        'compatibility' property is set.)
action: The pool can be imported using its name or numeric identifier, though
        some features will not be available without an explicit 'zpool upgrade'.
config:

        otus                              ONLINE
          mirror-0                        ONLINE
            /home/user/zpoolexport/filea  ONLINE
            /home/user/zpoolexport/fileb  ONLINE
```
11. Импортируем пул

```
user@debian:~$ sudo zpool import -d zpoolexport/ otus
user@debian:~$ zpool status
  pool: otus
 state: ONLINE
status: Some supported and requested features are not enabled on the pool.
        The pool can still be used, but some features are unavailable.
action: Enable all features using 'zpool upgrade'. Once this is done,
        the pool may no longer be accessible by software that does not support
        the features. See zpool-features(7) for details.
config:

        NAME                              STATE     READ WRITE CKSUM
        otus                              ONLINE       0     0     0
          mirror-0                        ONLINE       0     0     0
            /home/user/zpoolexport/filea  ONLINE       0     0     0
            /home/user/zpoolexport/fileb  ONLINE       0     0     0
```
12. Выведем все параметры

```
user@debian:~$ zfs get all otus
NAME  PROPERTY              VALUE                  SOURCE
otus  type                  filesystem             -
otus  creation              Fri May 15  7:00 2020  -
otus  used                  2.04M                  -
otus  available             350M                   -
otus  referenced            24K                    -
otus  compressratio         1.00x                  -
otus  mounted               yes                    -
otus  quota                 none                   default
otus  reservation           none                   default
otus  recordsize            128K                   local
otus  mountpoint            /otus                  default
otus  sharenfs              off                    default
otus  checksum              sha256                 local
otus  compression           zle                    local
otus  atime                 on                     default
otus  devices               on                     default
otus  exec                  on                     default
otus  setuid                on                     default
otus  readonly              off                    default
otus  zoned                 off                    default
otus  snapdir               hidden                 default
otus  aclmode               discard                default
otus  aclinherit            restricted             default
otus  createtxg             1                      -
otus  canmount              on                     default
otus  xattr                 on                     default
otus  copies                1                      default
otus  version               5                      -
otus  utf8only              off                    -
otus  normalization         none                   -
otus  casesensitivity       sensitive              -
otus  vscan                 off                    default
otus  nbmand                off                    default
otus  sharesmb              off                    default
otus  refquota              none                   default
otus  refreservation        none                   default
otus  guid                  14592242904030363272   -
otus  primarycache          all                    default
otus  secondarycache        all                    default
otus  usedbysnapshots       0B                     -
otus  usedbydataset         24K                    -
otus  usedbychildren        2.01M                  -
otus  usedbyrefreservation  0B                     -
otus  logbias               latency                default
otus  objsetid              54                     -
otus  dedup                 off                    default
otus  mlslabel              none                   default
otus  sync                  standard               default
otus  dnodesize             legacy                 default
otus  refcompressratio      1.00x                  -
otus  written               24K                    -
otus  logicalused           1020K                  -
otus  logicalreferenced     12K                    -
otus  volmode               default                default
otus  filesystem_limit      none                   default
otus  snapshot_limit        none                   default
otus  filesystem_count      none                   default
otus  snapshot_count        none                   default
otus  snapdev               hidden                 default
otus  acltype               off                    default
otus  context               none                   default
otus  fscontext             none                   default
otus  defcontext            none                   default
otus  rootcontext           none                   default
otus  relatime              on                     default
otus  redundant_metadata    all                    default
otus  overlay               on                     default
otus  encryption            off                    default
otus  keylocation           none                   default
otus  keyformat             none                   default
otus  pbkdf2iters           0                      default
otus  special_small_blocks  0                      default
otus  prefetch              all                    default
otus  direct                standard               default
otus  longname              off                    default
```
13. Выведем отдельно параметры

```
user@debian:~$ zfs get available otus
NAME  PROPERTY   VALUE  SOURCE
otus  available  350M   -
user@debian:~$ zfs get readonly otus
NAME  PROPERTY  VALUE   SOURCE
otus  readonly  off     default
user@debian:~$ zfs get compression otus
NAME  PROPERTY     VALUE           SOURCE
otus  compression  zle             local
user@debian:~$ zfs get compressratio otus
NAME  PROPERTY       VALUE  SOURCE
otus  compressratio  1.00x  -
user@debian:~$ zfs get checksum otus
NAME  PROPERTY  VALUE      SOURCE
otus  checksum  sha256     local
user@debian:~$ zfs get recordsize otus
NAME  PROPERTY    VALUE    SOURCE
otus  recordsize  128K     local

```
14. Скачиваем файл для поиска сообщения

```
user@debian:~$ wget -O otus_task2.file --no-check-certificate https://drive.usercontent.google.com/download?id=1wgxjih
8YZ-cqLqaZVa0lA3h3Y029c3oI&export=download
```
15. Восстанавливаем файловую систему

```
user@debian:~$ sudo zfs receive otus/test@today < otus_task2.file
```
16. Ищем скрытый файл и выводим его

```
user@debian:~$ cat $(find /otus/test -iname "secret_message")
https://otus.ru/lessons/linux-hl/
```