## Домашнее задание

### Обновление ядра системы
#### Цель:

- научиться обновлять ядро в ОС Linux;

#### Описание/Пошаговая инструкция выполнения домашнего задания:

Что потребуется сделать?

- Запустить ВМ c Ubuntu.
- Обновить ядро ОС на новейшую стабильную версию из mainline-репозитория.
- Оформить отчет в README-файле в GitHub-репозитории.

#### Дополнительное задание
- Собрать ядро самостоятельно из исходных кодов.

#### Отчет

##### Стенд

- Виртуальная машина с ОС `Debian 12`
- ОЗУ: 4 Гб
- ЦПУ: 2 ядра

##### Основное задание

1. После установки и обновления системы проверяем версию ядра

```
user@debian:~$ uname -r
6.1.0-37-amd64
```
2. Добавляем `backports` репозиторий для обновления ядра до последней официально поддерживаемой версии
```
user@debian:~$ cat /etc/apt/sources.list.d/debian-12-backports.list
deb http://deb.debian.org/debian bookworm-backports main
```
3. Проверяем, какие есть версии ядра в репозитории
```
user@debian:~$ sudo apt-cache search linux-image
...
linux-headers-6.12.27+bpo-amd64 - Header files for Linux 6.12.27+bpo-amd64
...
```
4. Устанавливаем наиболее новую версию ядра, а именно `6.12.27+bpo`
```
user@debian:~$ sudo apt install linux-headers-6.12.27+bpo-amd64
```
5. Проверяем успешную установку
```
user@debian:~$ dpkg --list | grep linux-image
ii  linux-image-6.1.0-35-amd64       6.1.137-1                      amd64        Linux 6.1 for 64-bit PCs                                                     (signed)
ii  linux-image-6.1.0-37-amd64       6.1.140-1                      amd64        Linux 6.1 for 64-bit PCs                                                     (signed)
ii  linux-image-6.12.27+bpo-amd64    6.12.27-1~bpo12+1              amd64        Linux 6.12 for 64-bit PCs                                                     (signed)
ii  linux-image-amd64                6.1.140-1                      amd64        Linux for 64-bit PCs (met                                                    a-package)
```
6. Перезагружаем виртуальную машину
```
user@debian:~$ sudo reboot
```
7. Проверяем версию ядра
```
user@debian:~$ uname -r
6.12.27+bpo-amd64
```

##### Дополнительное задание

1. Проверяем текущую версию ядра
```
user@debian:~$ uname -r
6.12.27+bpo-amd64
```
2. Создаем папку для работы с исходным кодом ядра и переходим в нее
```
user@debian:~$ mkdir kernel
user@debian:~$ cd kernel/
```
3. Скачиваем стабильную актуальную версию ядра из `kernel.org` и `GPG` ключ
```
user@debian:~/kernel$ wget https://cdn.kernel.org/pub/linux/kernel/v6.x/linux-6.15.2.tar.xz
...
user@debian:~/kernel$ wget https://cdn.kernel.org/pub/linux/kernel/v6.x/linux-6.15.2.tar.sign
...
```
4. Распаковывем архив с исходным кодом ядра, который скачали
```
tar -xvf linux-6.15.2.tar.xz
```
5. Используя `GPG` ключ, проверяем архив
```
user@debian:~/kernel$ gpg --verify -vvvv linux-6.15.2.tar.sign
...
:signature packet: algo 1, keyid 38DBBDC86092693E
...
user@debian:~/kernel$ gpg --search-keys 38DBBDC86092693E
...
```
6. Переходим в папку распакованным ядром
```
user@debian:~/kernel$ cd linux-6.15.2/
```
7. Устанавливаем необходимые пакеты для сборки ядра
```
sudo apt install -y build-essential dwarves python3 libncurses-dev flex bison libssl-dev bc libelf-dev
```
8. Не меняя дефолтную конфигурацию ядра, начинаем компилировать ядро и устанавливать модули ядра
```
user@debian:~/kernel$ sudo make bzImage
...
Kernel: arch/x86/boot/bzImage is ready  (#1)
user@debian:~/kernel$ sudo make modules
...
user@debian:~/kernel$ sudo make modules_install
...
```
9. Устанавливаем скомпилированное ядро
```
user@debian:~/kernel$ sudo make install
...
```
10. Обновляем конфигурацию `GRUB`
```
user@debian:~/kernel$ sudo update-grub
  INSTALL /boot
run-parts: executing /etc/kernel/postinst.d/initramfs-tools 6.15.2 /boot/vmlinuz-6.15.2
update-initramfs: Generating /boot/initrd.img-6.15.2
run-parts: executing /etc/kernel/postinst.d/zz-update-grub 6.15.2 /boot/vmlinuz-6.15.2
Generating grub configuration file ...
Found linux image: /boot/vmlinuz-6.15.2
Found initrd image: /boot/initrd.img-6.15.2
Found linux image: /boot/vmlinuz-6.12.27+bpo-amd64
Found initrd image: /boot/initrd.img-6.12.27+bpo-amd64
Found linux image: /boot/vmlinuz-6.1.0-37-amd64
Found initrd image: /boot/initrd.img-6.1.0-37-amd64
Found linux image: /boot/vmlinuz-6.1.0-35-amd64
Found initrd image: /boot/initrd.img-6.1.0-35-amd64
Warning: os-prober will not be executed to detect other bootable partitions.
Systems on them will not be added to the GRUB boot configuration.
Check GRUB_DISABLE_OS_PROBER documentation entry.
done
```
11. Перезагружаем виртуальную машину
```
user@debian:~$ sudo reboot
```
12. Проверяем версию ядра
```
user@debian:~$ uname -r
6.15.2
```
