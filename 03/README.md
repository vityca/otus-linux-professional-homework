## Домашнее задание

### Работа с LVM
#### Задание

- Настроить LVM
- Создать Physical Volume, Volume Group и Logical Volume
- Отформатировать и смонтировать файловую систему
- Расширить файловую систему за счёт нового диска
- Выполнить resize
- Проверить корректность работы

#### Отчет

##### Стенд

- Виртуальная машина с ОС `Debian 12`
- ОЗУ: 4 Гб
- ЦПУ: 2 ядра

##### Основное задание

1. Определяем доступные устройства

```
user@debian:~$ lsblk
NAME   MAJ:MIN RM  SIZE RO TYPE MOUNTPOINTS
sda      8:0    0   60G  0 disk
├─sda1   8:1    0   59G  0 part /
├─sda2   8:2    0    1K  0 part
└─sda5   8:5    0  975M  0 part [SWAP]
sdb      8:16   0   10G  0 disk
sdc      8:32   0   10G  0 disk
sdd      8:48   0   10G  0 disk
sde      8:64   0   10G  0 disk
sr0     11:0    1  670M  0 rom
```
2. Проверяем диски

```
user@debian:~$ sudo lvmdiskscan
  /dev/sda1 [      59.04 GiB]
  /dev/sda5 [     975.00 MiB]
  /dev/sdb  [      10.00 GiB]
  /dev/sdc  [      10.00 GiB]
  /dev/sdd  [      10.00 GiB]
  /dev/sde  [      10.00 GiB]
  4 disks
  2 partitions
  0 LVM physical volume whole disks
  0 LVM physical volumes
```
3. Cоздаем `Physical Volume`

```
user@debian:~$ sudo pvcreate /dev/sdb
  Physical volume "/dev/sdb" successfully created.
```
4. Создаем `Volume Group` с названием `volume1`

```
user@debian:~$ sudo vgcreate volume1 /dev/sdb
  Volume group "volume1" successfully created
```
5. Смотрим статус `vg

```
user@debian:~$ sudo vgdisplay -v volume1
  --- Volume group ---
  VG Name               volume1
  System ID
  Format                lvm2
  Metadata Areas        1
  Metadata Sequence No  1
  VG Access             read/write
  VG Status             resizable
  MAX LV                0
  Cur LV                0
  Open LV               0
  Max PV                0
  Cur PV                1
  Act PV                1
  VG Size               <10.00 GiB
  PE Size               4.00 MiB
  Total PE              2559
  Alloc PE / Size       0 / 0
  Free  PE / Size       2559 / <10.00 GiB
  VG UUID               yjB9a4-iawu-2Eh3-CQP8-VudI-qwVq-XzL3au

  --- Physical volumes ---
  PV Name               /dev/sdb
  PV UUID               dxaIhR-oasA-W20M-c7bm-RnGf-k8UR-6k3DNB
  PV Status             allocatable
  Total PE / Free PE    2559 / 2559

user@debian:~$ sudo vgdisplay volume1
  --- Volume group ---
  VG Name               volume1
  System ID
  Format                lvm2
  Metadata Areas        1
  Metadata Sequence No  1
  VG Access             read/write
  VG Status             resizable
  MAX LV                0
  Cur LV                0
  Open LV               0
  Max PV                0
  Cur PV                1
  Act PV                1
  VG Size               <10.00 GiB
  PE Size               4.00 MiB
  Total PE              2559
  Alloc PE / Size       0 / 0
  Free  PE / Size       2559 / <10.00 GiB
  VG UUID               yjB9a4-iawu-2Eh3-CQP8-VudI-qwVq-XzL3au
```
6. Создаем `lv` в созданной `vg`

```
user@debian:~$ sudo lvcreate --size 8G --name lv-volume1 volume1
  Logical volume "lv-volume1" created.
```
7. Проверяем статус `vg`

```
user@debian:~$ sudo vgdisplay -v volume1
  --- Volume group ---
  VG Name               volume1
  System ID
  Format                lvm2
  Metadata Areas        1
  Metadata Sequence No  2
  VG Access             read/write
  VG Status             resizable
  MAX LV                0
  Cur LV                1
  Open LV               0
  Max PV                0
  Cur PV                1
  Act PV                1
  VG Size               <10.00 GiB
  PE Size               4.00 MiB
  Total PE              2559
  Alloc PE / Size       2048 / 8.00 GiB
  Free  PE / Size       511 / <2.00 GiB
  VG UUID               yjB9a4-iawu-2Eh3-CQP8-VudI-qwVq-XzL3au

  --- Logical volume ---
  LV Path                /dev/volume1/lv-volume1
  LV Name                lv-volume1
  VG Name                volume1
  LV UUID                Exg4xB-g73v-CXkn-Csrx-oSmN-d0IF-pxPBKb
  LV Write Access        read/write
  LV Creation host, time debian, 2025-06-30 21:56:54 +0300
  LV Status              available
  # open                 0
  LV Size                8.00 GiB
  Current LE             2048
  Segments               1
  Allocation             inherit
  Read ahead sectors     auto
  - currently set to     256
  Block device           253:0

  --- Physical volumes ---
  PV Name               /dev/sdb
  PV UUID               dxaIhR-oasA-W20M-c7bm-RnGf-k8UR-6k3DNB
  PV Status             allocatable
  Total PE / Free PE    2559 / 511

```
8. Проверяем статус `lv`

```
user@debian:~$ sudo lvdisplay /dev/volume1
  --- Logical volume ---
  LV Path                /dev/volume1/lv-volume1
  LV Name                lv-volume1
  VG Name                volume1
  LV UUID                Exg4xB-g73v-CXkn-Csrx-oSmN-d0IF-pxPBKb
  LV Write Access        read/write
  LV Creation host, time debian, 2025-06-30 21:56:54 +0300
  LV Status              available
  # open                 0
  LV Size                8.00 GiB
  Current LE             2048
  Segments               1
  Allocation             inherit
  Read ahead sectors     auto
  - currently set to     256
  Block device           253:0

user@debian:~$ sudo lvdisplay /dev/volume1/lv-volume1
  --- Logical volume ---
  LV Path                /dev/volume1/lv-volume1
  LV Name                lv-volume1
  VG Name                volume1
  LV UUID                Exg4xB-g73v-CXkn-Csrx-oSmN-d0IF-pxPBKb
  LV Write Access        read/write
  LV Creation host, time debian, 2025-06-30 21:56:54 +0300
  LV Status              available
  # open                 0
  LV Size                8.00 GiB
  Current LE             2048
  Segments               1
  Allocation             inherit
  Read ahead sectors     auto
  - currently set to     256
  Block device           253:0

```
9. В сжатом виде

```
user@debian:~$ sudo vgs
  VG      #PV #LV #SN Attr   VSize   VFree
  volume1   1   1   0 wz--n- <10.00g <2.00g
user@debian:~$ sudo lvs
  LV         VG      Attr       LSize Pool Origin Data%  Meta%  Move Log Cpy%Sync Convert
  lv-volume1 volume1 -wi-a----- 8.00g
```
10. Создаем и проверяем маленький `lv`

```
user@debian:~$ sudo lvcreate -L500M -n small volume1
  Logical volume "small" created.
user@debian:~$ sudo lvs
  LV         VG      Attr       LSize   Pool Origin Data%  Meta%  Move Log Cpy%Sync Convert
  lv-volume1 volume1 -wi-a-----   8.00g
  small      volume1 -wi-a----- 500.00m
```
11. Создаем файловую систему на `lv` и монтируем

```
user@debian:~$ sudo mkfs.ext4 /dev/volume1/lv-volume1
mke2fs 1.47.0 (5-Feb-2023)
Discarding device blocks: done
Creating filesystem with 2097152 4k blocks and 524288 inodes
Filesystem UUID: 915a4299-0ce4-4762-aca0-1701271b41d2
Superblock backups stored on blocks:
        32768, 98304, 163840, 229376, 294912, 819200, 884736, 1605632

Allocating group tables: done
Writing inode tables: done
Creating journal (16384 blocks): done
Writing superblocks and filesystem accounting information: done

user@debian:~$ mkdir /tmp/volume1
user@debian:~$ mount /dev/volume1/lv-volume1 /tmp/volume1/
mount: /tmp/volume1: must be superuser to use mount.
       dmesg(1) may have more information after failed mount system call.
user@debian:~$ sudo mount /dev/volume1/lv-volume1 /tmp/volume1/
user@debian:~$ mount | grep volume1
/dev/mapper/volume1-lv--volume1 on /tmp/volume1 type ext4 (rw,relatime)
```
12. Переходим к расширению

```
user@debian:~$ sudo pvs
  PV         VG      Fmt  Attr PSize   PFree
  /dev/sdb   volume1 lvm2 a--  <10.00g <1.51g
user@debian:~$ sudo pvcreate /dev/sdc
  Physical volume "/dev/sdc" successfully created.
user@debian:~$ sudo vgextend volume1 /dev/sdc
  Volume group "volume1" successfully extended
user@debian:~$ sudo vgdisplay -v volume1
  --- Volume group ---
  VG Name               volume1
  System ID
  Format                lvm2
  Metadata Areas        2
  Metadata Sequence No  4
  VG Access             read/write
  VG Status             resizable
  MAX LV                0
  Cur LV                2
  Open LV               1
  Max PV                0
  Cur PV                2
  Act PV                2
  VG Size               19.99 GiB
  PE Size               4.00 MiB
  Total PE              5118
  Alloc PE / Size       2173 / <8.49 GiB
  Free  PE / Size       2945 / 11.50 GiB
  VG UUID               yjB9a4-iawu-2Eh3-CQP8-VudI-qwVq-XzL3au

  --- Logical volume ---
  LV Path                /dev/volume1/lv-volume1
  LV Name                lv-volume1
  VG Name                volume1
  LV UUID                Exg4xB-g73v-CXkn-Csrx-oSmN-d0IF-pxPBKb
  LV Write Access        read/write
  LV Creation host, time debian, 2025-06-30 21:56:54 +0300
  LV Status              available
  # open                 1
  LV Size                8.00 GiB
  Current LE             2048
  Segments               1
  Allocation             inherit
  Read ahead sectors     auto
  - currently set to     256
  Block device           253:0

  --- Logical volume ---
  LV Path                /dev/volume1/small
  LV Name                small
  VG Name                volume1
  LV UUID                VnnreF-MNB0-rYFL-87yP-qy1w-vvsg-eK2iZl
  LV Write Access        read/write
  LV Creation host, time debian, 2025-06-30 22:16:20 +0300
  LV Status              available
  # open                 0
  LV Size                8.00 GiB
  Current LE             2048
  Segments               1
  Allocation             inherit
  Read ahead sectors     auto
  - currently set to     256
  Block device           253:0

  --- Logical volume ---
  LV Path                /dev/volume1/small
  LV Name                small
  VG Name                volume1
  LV UUID                VnnreF-MNB0-rYFL-87yP-qy1w-vvsg-eK2iZl
  LV Write Access        read/write
  LV Creation host, time debian, 2025-06-30 22:16:20 +0300
  LV Status              available
  # open                 0
  LV Size                500.00 MiB
  Current LE             125
  Segments               1
  Allocation             inherit
  Read ahead sectors     auto
  - currently set to     256
  Block device           253:1

  --- Physical volumes ---
  PV Name               /dev/sdb
  PV UUID               dxaIhR-oasA-W20M-c7bm-RnGf-k8UR-6k3DNB
  PV Status             allocatable
  Total PE / Free PE    2559 / 386

  PV Name               /dev/sdc
  PV UUID               CQwAsb-vYVL-FwPW-507E-8iUR-4YnN-Fiu2X4
  PV Status             allocatable
  Total PE / Free PE    2559 / 2559
```
13. Проверяем

```
user@debian:~$ sudo vgs
  VG      #PV #LV #SN Attr   VSize  VFree
  volume1   2   2   0 wz--n- 19.99g 11.50g
```
14. Забьем место на нашем диске

```
user@debian:~$ sudo dd if=/dev/zero of=/tmp/volume1/dd.log bs=1M count=8000 status=progress
8262778880 bytes (8.3 GB, 7.7 GiB) copied, 9 s, 918 MB/s
dd: error writing '/tmp/volume1/dd.log': No space left on device
7948+0 records in
7947+0 records out
8333492224 bytes (8.3 GB, 7.8 GiB) copied, 9.05607 s, 920 MB/s
user@debian:~$ df -h
Filesystem                       Size  Used Avail Use% Mounted on
udev                             1.9G     0  1.9G   0% /dev
tmpfs                            392M  556K  391M   1% /run
/dev/sda1                         58G  1.7G   54G   4% /
tmpfs                            2.0G     0  2.0G   0% /dev/shm
tmpfs                            5.0M     0  5.0M   0% /run/lock
tmpfs                            392M     0  392M   0% /run/user/1000
/dev/mapper/volume1-lv--volume1  7.8G  7.8G     0 100% /tmp/volume1
```
15. Увеличиваем объем диска

```
user@debian:~$ sudo lvextend -L+8G /dev/volume1/lv-volume1
  Size of logical volume volume1/lv-volume1 changed from 8.00 GiB (2048 extents) to 16.00 GiB (4096 extents).
  Logical volume volume1/lv-volume1 successfully resized.
```
16. Проверяем

```
user@debian:~$ sudo vgs
  VG      #PV #LV #SN Attr   VSize  VFree
  volume1   2   2   0 wz--n- 19.99g 3.50g
```
```
user@debian:~$ sudo lvs /dev/volume1/lv-volume1
  LV         VG      Attr       LSize  Pool Origin Data%  Meta%  Move Log Cpy%Sync Convert
  lv-volume1 volume1 -wi-ao---- 16.00g
```
```
user@debian:~$ df -h
Filesystem                       Size  Used Avail Use% Mounted on
udev                             1.9G     0  1.9G   0% /dev
tmpfs                            392M  556K  391M   1% /run
/dev/sda1                         58G  1.7G   54G   4% /
tmpfs                            2.0G     0  2.0G   0% /dev/shm
tmpfs                            5.0M     0  5.0M   0% /run/lock
tmpfs                            392M     0  392M   0% /run/user/1000
/dev/mapper/volume1-lv--volume1  7.8G  7.8G     0 100% /tmp/volume1
```
```
user@debian:~$ sudo resize2fs /dev/volume1/lv-volume1
resize2fs 1.47.0 (5-Feb-2023)
Filesystem at /dev/volume1/lv-volume1 is mounted on /tmp/volume1; on-line resizing required
old_desc_blocks = 1, new_desc_blocks = 2
The filesystem on /dev/volume1/lv-volume1 is now 4194304 (4k) blocks long.

user@debian:~$ df -h
Filesystem                       Size  Used Avail Use% Mounted on
udev                             1.9G     0  1.9G   0% /dev
tmpfs                            392M  556K  391M   1% /run
/dev/sda1                         58G  1.7G   54G   4% /
tmpfs                            2.0G     0  2.0G   0% /dev/shm
tmpfs                            5.0M     0  5.0M   0% /run/lock
tmpfs                            392M     0  392M   0% /run/user/1000
/dev/mapper/volume1-lv--volume1   16G  7.8G  7.2G  53% /tmp/volume1
```
17. Сделаем вид, что добавили больше, чем нужно и переразметим

```
user@debian:~$ sudo e2fsck -fy /dev/volume1/lv-volume1
e2fsck 1.47.0 (5-Feb-2023)
Pass 1: Checking inodes, blocks, and sizes
Pass 2: Checking directory structure
Pass 3: Checking directory connectivity
Pass 4: Checking reference counts
Pass 5: Checking group summary information
/dev/volume1/lv-volume1: 12/1048576 files (0.0% non-contiguous), 2128002/4194304 blocks
user@debian:~$ sudo resize2fs /dev/volume1/lv-volume1 11G
resize2fs 1.47.0 (5-Feb-2023)
Resizing the filesystem on /dev/volume1/lv-volume1 to 2883584 (4k) blocks.
The filesystem on /dev/volume1/lv-volume1 is now 2883584 (4k) blocks long.

user@debian:~$ sudo lvre
lvreduce  lvremove  lvrename  lvresize
user@debian:~$ sudo lvre
lvreduce  lvremove  lvrename  lvresize
user@debian:~$ sudo lvreduce /dev/volume1/lv-volume1 -L 11G
  WARNING: Reducing active logical volume to 11.00 GiB.
  THIS MAY DESTROY YOUR DATA (filesystem etc.)
Do you really want to reduce volume1/lv-volume1? [y/n]: y
  Size of logical volume volume1/lv-volume1 changed from 16.00 GiB (4096 extents) to 11.00 GiB (2816 extents).
  Logical volume volume1/lv-volume1 successfully resized.
user@debian:~$ sudo mount /dev/volume1/lv-volume1 /tmp/volume1/
user@debian:~$ df -h
Filesystem                       Size  Used Avail Use% Mounted on
udev                             1.9G     0  1.9G   0% /dev
tmpfs                            392M  556K  391M   1% /run
/dev/sda1                         58G  1.7G   54G   4% /
tmpfs                            2.0G     0  2.0G   0% /dev/shm
tmpfs                            5.0M     0  5.0M   0% /run/lock
tmpfs                            392M     0  392M   0% /run/user/1000
/dev/mapper/volume1-lv--volume1   11G  7.8G  2.5G  76% /tmp/volume1
user@debian:~$ sudo lvs /dev/volume1/lv-volume1
  LV         VG      Attr       LSize  Pool Origin Data%  Meta%  Move Log Cpy%Sync Convert
  lv-volume1 volume1 -wi-ao---- 11.00g
```
18. Создадим снапшот

```
user@debian:~$ sudo lvcreate -L 1G -s -n volume1-snap /dev/mapper/volume1-lv--volume1
  Logical volume "volume1-snap" created.
```
19. Проверим, что он создался

```
user@debian:~$ sudo vgs -o +lv_size,lv_name
  VG      #PV #LV #SN Attr   VSize  VFree LSize   LV
  volume1   2   3   1 wz--n- 19.99g 7.50g  11.00g lv-volume1
  volume1   2   3   1 wz--n- 19.99g 7.50g 500.00m small
  volume1   2   3   1 wz--n- 19.99g 7.50g   1.00g volume1-snap
```
```
user@debian:~$ lsblk
NAME                        MAJ:MIN RM  SIZE RO TYPE MOUNTPOINTS
sda                           8:0    0   60G  0 disk
├─sda1                        8:1    0   59G  0 part /
├─sda2                        8:2    0    1K  0 part
└─sda5                        8:5    0  975M  0 part [SWAP]
sdb                           8:16   0   10G  0 disk
├─volume1-small             254:1    0  500M  0 lvm
└─volume1-lv--volume1-real  254:2    0   11G  0 lvm
  ├─volume1-lv--volume1     254:0    0   11G  0 lvm
  └─volume1-volume1--snap   254:4    0   11G  0 lvm
sdc                           8:32   0   10G  0 disk
├─volume1-lv--volume1-real  254:2    0   11G  0 lvm
│ ├─volume1-lv--volume1     254:0    0   11G  0 lvm
│ └─volume1-volume1--snap   254:4    0   11G  0 lvm
└─volume1-volume1--snap-cow 254:3    0    1G  0 lvm
  └─volume1-volume1--snap   254:4    0   11G  0 lvm
sdd                           8:48   0   10G  0 disk
sde                           8:64   0   10G  0 disk
sr0                          11:0    1  670M  0 rom
```
```
user@debian:/mnt$ lsblk
NAME                        MAJ:MIN RM  SIZE RO TYPE MOUNTPOINTS
sda                           8:0    0   60G  0 disk
├─sda1                        8:1    0   59G  0 part /
├─sda2                        8:2    0    1K  0 part
└─sda5                        8:5    0  975M  0 part [SWAP]
sdb                           8:16   0   10G  0 disk
├─volume1-small             254:1    0  500M  0 lvm
└─volume1-lv--volume1-real  254:2    0   11G  0 lvm
  ├─volume1-lv--volume1     254:0    0   11G  0 lvm  /mnt/volume1
  └─volume1-volume1--snap   254:4    0   11G  0 lvm  /mnt/volume1-snap
sdc                           8:32   0   10G  0 disk
├─volume1-lv--volume1-real  254:2    0   11G  0 lvm
│ ├─volume1-lv--volume1     254:0    0   11G  0 lvm  /mnt/volume1
│ └─volume1-volume1--snap   254:4    0   11G  0 lvm  /mnt/volume1-snap
└─volume1-volume1--snap-cow 254:3    0    1G  0 lvm
  └─volume1-volume1--snap   254:4    0   11G  0 lvm  /mnt/volume1-snap
sdd                           8:48   0   10G  0 disk
sde                           8:64   0   10G  0 disk
sr0                          11:0    1  670M  0 rom
```
20. Смонитируем снапшот в папку

```
user@debian:/mnt$ sudo mkdir volume1-snap
user@debian:/mnt$ sudo mount /dev/volume1/volume1-snap volume1-snap/
```
21. Проверим

```
user@debian:/mnt$ lsblk
NAME                        MAJ:MIN RM  SIZE RO TYPE MOUNTPOINTS
sda                           8:0    0   60G  0 disk
├─sda1                        8:1    0   59G  0 part /
├─sda2                        8:2    0    1K  0 part
└─sda5                        8:5    0  975M  0 part [SWAP]
sdb                           8:16   0   10G  0 disk
├─volume1-small             254:1    0  500M  0 lvm
└─volume1-lv--volume1-real  254:2    0   11G  0 lvm
  ├─volume1-lv--volume1     254:0    0   11G  0 lvm  /mnt/volume1
  └─volume1-volume1--snap   254:4    0   11G  0 lvm  /mnt/volume1-snap
sdc                           8:32   0   10G  0 disk
├─volume1-lv--volume1-real  254:2    0   11G  0 lvm
│ ├─volume1-lv--volume1     254:0    0   11G  0 lvm  /mnt/volume1
│ └─volume1-volume1--snap   254:4    0   11G  0 lvm  /mnt/volume1-snap
└─volume1-volume1--snap-cow 254:3    0    1G  0 lvm
  └─volume1-volume1--snap   254:4    0   11G  0 lvm  /mnt/volume1-snap
sdd                           8:48   0   10G  0 disk
sde                           8:64   0   10G  0 disk
sr0                          11:0    1  670M  0 rom
user@debian:/mnt$ ls volume1-snap/
dd.log  lost+found

```
```
user@debian:/mnt$ sudo umount volume1-snap
```
22. Удалим файл в исходном диске

```
user@debian:/mnt$ sudo rm volume1/dd.log
user@debian:/mnt$ ls volume1/
lost+found
```
23. Мерджим

```
user@debian:/mnt$ sudo umount volume1
user@debian:/mnt$ sudo lvconvert --merge /dev/volume1/volume1-snap
  Merging of volume volume1/volume1-snap started.
  volume1/lv-volume1: Merged: 100.00%
```
24. Проверяем

```
user@debian:/mnt$ sudo mount /dev/volume1/lv-volume1 volume1
user@debian:/mnt$ ls volume1
dd.log  lost+found
```
25. Найдем UUID диска

```
user@debian:/mnt$ sudo blkid
/dev/sdb: UUID="dxaIhR-oasA-W20M-c7bm-RnGf-k8UR-6k3DNB" TYPE="LVM2_member"
/dev/sr0: BLOCK_SIZE="2048" UUID="2025-05-17-09-55-45-00" LABEL="Debian 12.11.0 amd64 n" TYPE="iso9660" PTUUID="47446751" PTTYPE="dos"
/dev/mapper/volume1-lv--volume1: UUID="915a4299-0ce4-4762-aca0-1701271b41d2" BLOCK_SIZE="4096" TYPE="ext4"
/dev/sdc: UUID="CQwAsb-vYVL-FwPW-507E-8iUR-4YnN-Fiu2X4" TYPE="LVM2_member"
/dev/sda5: UUID="342d34a1-6e45-4522-ac53-5cbae4b051c7" TYPE="swap" PARTUUID="894d61da-05"
/dev/sda1: UUID="32e4b690-5a78-49f1-b742-8fae43ab76a9" BLOCK_SIZE="4096" TYPE="ext4" PARTUUID="894d61da-01"
```
26. Изменим файл `/etc/fstab`

```
...
UUID=915a4299-0ce4-4762-aca0-1701271b41d2       /mnt/volume1    ext4    defaults        0       2
```
27. Отмонтируем `volume1` и проверим корректность

```
user@debian:/mnt$ sudo umount volume1
user@debian:/mnt$ ls -la volume1
total 8
drwxr-xr-x 2 root root 4096 Aug 23 18:45 .
drwxr-xr-x 4 root root 4096 Aug 23 18:46 ..
```
28. Смонтируем диск через `fstab`

```
user@debian:~$ sudo mount -a
user@debian:/mnt$ ls volume1
dd.log  lost+found
```