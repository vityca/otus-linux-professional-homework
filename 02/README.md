## Домашнее задание

### Работа с mdadm
#### Задание

- Добавить в виртуальную машину несколько дисков
- Собрать `RAID`-0/1/5/10 на выбор
- Сломать и починить `RAID`
- Создать `GPT` таблицу, пять разделов и смонтировать их в системе
- Написать скрипт создания `RAID`-массива

#### Отчет

##### Стенд

- Виртуальная машина с ОС `Debian 12`
- ОЗУ: 4 Гб
- ЦПУ: 2 ядра

##### Основное задание

1. Проверяем наличие дисков в системе
```
user@debian:~$ lsblk -l
NAME MAJ:MIN RM  SIZE RO TYPE MOUNTPOINTS
sda    8:0    0   60G  0 disk
sda1   8:1    0   59G  0 part /
sda2   8:2    0    1K  0 part
sda5   8:5    0  975M  0 part [SWAP]
sr0   11:0    1  670M  0 rom
```

2. После добавления дисков виртуальную машину снова проверяем их наличие (`sdb`, `sdc`, `sdd` по `10Гб`)
```
user@debian:~$ lsblk -l
NAME MAJ:MIN RM  SIZE RO TYPE MOUNTPOINTS
sda    8:0    0   60G  0 disk
sda1   8:1    0   59G  0 part /
sda2   8:2    0    1K  0 part
sda5   8:5    0  975M  0 part [SWAP]
sdb    8:16   0   10G  0 disk
sdc    8:32   0   10G  0 disk
sdd    8:48   0   10G  0 disk
sr0   11:0    1  670M  0 rom
```

3. Устанавливаем `mdadm` для управления `RAID`-массивами
```
user@debian:~$ sudo apt install mdadm
...
```

4. Проверяем наличие `RAID`-массивов
```
user@debian:~$ cat /proc/mdstat
Personalities :
unused devices: <none>
```

5. Зануляем диски, с которыми будем работать и убеждаемся, что ранее они не состояли в `RAID`-массиве
```
user@debian:~$ sudo mdadm --zero-superblock --force /dev/sd{b,c,d}
mdadm: Unrecognised md component device - /dev/sdb
mdadm: Unrecognised md component device - /dev/sdc
mdadm: Unrecognised md component device - /dev/sdd
```

6. Собираем `RAID`-1 из двух дисков
```
user@debian:~$ sudo mdadm -C -v /dev/md127 -n 2 -l 1 /dev/sdb /dev/sdc
...
mdadm: array /dev/md127 started.
```

7. Проверяем статус созданного `RAID`-массива
```
user@debian:~$ cat /proc/mdstat
Personalities : [raid1]
md127 : active raid1 sdc[1] sdb[0]
      10476544 blocks super 1.2 [2/2] [UU]

unused devices: <none>
user@debian:~$ lsblk -l
NAME  MAJ:MIN RM  SIZE RO TYPE  MOUNTPOINTS
sda     8:0    0   60G  0 disk
sda1    8:1    0   59G  0 part  /
sda2    8:2    0    1K  0 part
sda5    8:5    0  975M  0 part  [SWAP]
sdb     8:16   0   10G  0 disk
sdc     8:32   0   10G  0 disk
sdd     8:48   0   10G  0 disk
md127   9:127  0   10G  0 raid1
sr0    11:0    1  670M  0 rom
user@debian:~$ sudo mdadm -D /dev/md127
/dev/md127:
           Version : 1.2
     Creation Time : Tue Jun 17 23:24:09 2025
        Raid Level : raid1
        Array Size : 10476544 (9.99 GiB 10.73 GB)
     Used Dev Size : 10476544 (9.99 GiB 10.73 GB)
      Raid Devices : 2
     Total Devices : 2
       Persistence : Superblock is persistent

       Update Time : Tue Jun 17 23:25:01 2025
             State : clean
    Active Devices : 2
   Working Devices : 2
    Failed Devices : 0
     Spare Devices : 0

Consistency Policy : resync

              Name : debian:127  (local to host debian)
              UUID : ef686c75:1d121d1c:cc0bf7ce:6ad7540a
            Events : 17

    Number   Major   Minor   RaidDevice State
       0       8       16        0      active sync   /dev/sdb
       1       8       32        1      active sync   /dev/sdc
```

8. "Сломаем" один из дисков в массиве
```
user@debian:~$ sudo mdadm /dev/md127 -f /dev/sdc
mdadm: set /dev/sdc faulty in /dev/md127
```

9. Проверяем статус `RAID`-массива
```
user@debian:~$ cat /proc/mdstat
Personalities : [raid1]
md127 : active raid1 sdc[1](F) sdb[0]
      10476544 blocks super 1.2 [2/1] [U_]

unused devices: <none>
user@debian:~$ cat /proc/mdstat
Personalities : [raid1]
md127 : active raid1 sdc[1](F) sdb[0]
      10476544 blocks super 1.2 [2/1] [U_]

unused devices: <none>
user@debian:~$ sudo mdadm -D /dev/md127
/dev/md127:
           Version : 1.2
     Creation Time : Tue Jun 17 23:24:09 2025
        Raid Level : raid1
        Array Size : 10476544 (9.99 GiB 10.73 GB)
     Used Dev Size : 10476544 (9.99 GiB 10.73 GB)
      Raid Devices : 2
     Total Devices : 2
       Persistence : Superblock is persistent

       Update Time : Tue Jun 17 23:34:36 2025
             State : clean, degraded
    Active Devices : 1
   Working Devices : 1
    Failed Devices : 1
     Spare Devices : 0

Consistency Policy : resync

              Name : debian:127  (local to host debian)
              UUID : ef686c75:1d121d1c:cc0bf7ce:6ad7540a
            Events : 19

    Number   Major   Minor   RaidDevice State
       0       8       16        0      active sync   /dev/sdb
       -       0        0        1      removed

       1       8       32        -      faulty   /dev/sdc
```

10. Удаляем "сломанный" диск из массива
```
user@debian:~$ sudo mdadm /dev/md127 --remove /dev/sdc
mdadm: hot removed /dev/sdc from /dev/md127
user@debian:~$ sudo mdadm -D /dev/md127
/dev/md127:
           Version : 1.2
     Creation Time : Tue Jun 17 23:24:09 2025
        Raid Level : raid1
        Array Size : 10476544 (9.99 GiB 10.73 GB)
     Used Dev Size : 10476544 (9.99 GiB 10.73 GB)
      Raid Devices : 2
     Total Devices : 1
       Persistence : Superblock is persistent

       Update Time : Tue Jun 17 23:39:31 2025
             State : clean, degraded
    Active Devices : 1
   Working Devices : 1
    Failed Devices : 0
     Spare Devices : 0

Consistency Policy : resync

              Name : debian:127  (local to host debian)
              UUID : ef686c75:1d121d1c:cc0bf7ce:6ad7540a
            Events : 20

    Number   Major   Minor   RaidDevice State
       0       8       16        0      active sync   /dev/sdb
       -       0        0        1      removed
```

11. Добавим оставшийся диск, как замененный
```
user@debian:~$ sudo mdadm /dev/md127 --add /dev/sdd
mdadm: added /dev/sdd
user@debian:~$ sudo mdadm -D /dev/md127
...
    Rebuild Status : 19% complete
...
    Number   Major   Minor   RaidDevice State
       0       8       16        0      active sync   /dev/sdb
       2       8       48        1      spare rebuilding   /dev/sdd
user@debian:~$ sudo mdadm -D /dev/md127
/dev/md127:
           Version : 1.2
     Creation Time : Tue Jun 17 23:24:09 2025
        Raid Level : raid1
        Array Size : 10476544 (9.99 GiB 10.73 GB)
     Used Dev Size : 10476544 (9.99 GiB 10.73 GB)
      Raid Devices : 2
     Total Devices : 2
       Persistence : Superblock is persistent

       Update Time : Tue Jun 17 23:44:00 2025
             State : clean
    Active Devices : 2
   Working Devices : 2
    Failed Devices : 0
     Spare Devices : 0

Consistency Policy : resync

              Name : debian:127  (local to host debian)
              UUID : ef686c75:1d121d1c:cc0bf7ce:6ad7540a
            Events : 39

    Number   Major   Minor   RaidDevice State
       0       8       16        0      active sync   /dev/sdb
       2       8       48        1      active sync   /dev/sdd
user@debian:~$ cat /proc/mdstat
Personalities : [raid1]
md127 : active raid1 sdd[2] sdb[0]
      10476544 blocks super 1.2 [2/2] [UU]

unused devices: <none>
```

12. Устанавливаем `parted`
```
user@debian:~$ sudo apt install parted
...
```

13. Создаем таблицу `GPT` в `RAID`-массиве
```
user@debian:~$ sudo parted -s /dev/md127 mklabel gpt
```

14. Проверяем создание таблицы
```
user@debian:~$ sudo fdisk -l
...
Disk /dev/md127: 9.99 GiB, 10727981056 bytes, 20953088 sectors
Units: sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 512 bytes
Disklabel type: gpt
Disk identifier: 1F05DDD7-2D86-4D0C-B6CE-A74CF1DE9F8B
```

15. Создаем 5 равных разделов в `RAID`-массиве
```
sudo parted /dev/md127 mkpart primary ext4 0% 20%
sudo parted /dev/md127 mkpart primary ext4 20% 40%
sudo parted /dev/md127 mkpart primary ext4 40% %60
sudo parted /dev/md127 mkpart primary ext4 40% 60%
sudo parted /dev/md127 mkpart primary ext4 60% 80%
sudo parted /dev/md127 mkpart primary ext4 80% 100%
```

16. Создаем файловые системы на каждом из разделов
```
user@debian:~$ for i in $(seq 1 5); do sudo mkfs.ext4 /dev/md127p$i; done
```

17. Создаем папки для монтирования
```
user@debian:~$ mkdir -p /tmp/part{1,2,3,4,5}
user@debian:~$ ls /tmp/part*
/tmp/part1:

/tmp/part2:

/tmp/part3:

/tmp/part4:

/tmp/part5:
```

18. Монтируем партиции рейда по созданным папкам
```
user@debian:~$ for i in $(seq 1 5); do sudo mount /dev/md127p$i /tmp/part$i; done
```

19. Проверяем, что они смонтировались
```
user@debian:/tmp$ tree
.
├── part1
│   └── lost+found  [error opening dir]
├── part2
│   └── lost+found  [error opening dir]
├── part3
│   └── lost+found  [error opening dir]
├── part4
│   └── lost+found  [error opening dir]
├── part5
│   └── lost+found  [error opening dir]
...
user@debian:/tmp$ lsblk -l
NAME    MAJ:MIN RM  SIZE RO TYPE  MOUNTPOINTS
sda       8:0    0   60G  0 disk
sda1      8:1    0   59G  0 part  /
sda2      8:2    0    1K  0 part
sda5      8:5    0  975M  0 part  [SWAP]
sdb       8:16   0   10G  0 disk
sdc       8:32   0   10G  0 disk
sdd       8:48   0   10G  0 disk
md127     9:127  0   10G  0 raid1
sr0      11:0    1  670M  0 rom
md127p1 259:3    0    2G  0 part  /tmp/part1
md127p2 259:4    0    2G  0 part  /tmp/part2
md127p3 259:5    0    2G  0 part  /tmp/part3
md127p4 259:8    0    2G  0 part  /tmp/part4
md127p5 259:9    0    2G  0 part  /tmp/part5
```

20. Пишем результирующий [скрипт](./mdcreate.sh) для создания `RAID`-массива