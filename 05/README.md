## Домашнее задание

### Работа с NFS
#### Задание

- запустить 2 виртуальных машины (сервер `NFS` и клиента)
- на сервере `NFS` должна быть подготовлена и экспортирована директория
- в экспортированной директории должна быть поддиректория с именем `upload` с правами на запись в неё
- экспортированная директория должна автоматически монтироваться на клиенте при старте виртуальной машины (`systemd`, `autofs` или `fstab` — любым способом)
- монтирование и работа `NFS` на клиенте должна быть организована с использованием `NFSv3`
- создать два `bash`-скрипта для конфигурирования сервера и клиента

#### Отчет

##### Стенд
- `NFS`-сервер
    - Виртуальная машина с ОС `Debian 12`
    - ОЗУ: 4 Гб
    - ЦПУ: 2 ядра
- `NFS`-клиент
    - Виртуальная машина с ОС `Debian 12`
    - ОЗУ: 8 Гб
    - ЦПУ: 4 ядра

##### Основное задание

1. Устанавливаем серверный пакет `nfs`

```
user@debian:~$ sudo apt install nfs-kernel-server                                  
Reading package lists... Done
Building dependency tree... Done
Reading state information... Done
The following package was automatically installed and is no longer required:
  linux-image-6.1.0-35-amd64
Use 'sudo apt autoremove' to remove it.
The following additional packages will be installed:
  keyutils libnfsidmap1 libyaml-0-2 nfs-common python3-yaml rpcbind
...
```
2. Проверяем открытые порты

```
user@debian:~$ sudo ss -tulnp | grep -e "2049" -e "111"
udp   UNCONN 0      0            0.0.0.0:111        0.0.0.0:*    users:(("rpcbind",pid=53292,fd=5),("systemd",pid=1,fd=56))
udp   UNCONN 0      0               [::]:111           [::]:*    users:(("rpcbind",pid=53292,fd=7),("systemd",pid=1,fd=58))
tcp   LISTEN 0      64           0.0.0.0:2049       0.0.0.0:*
tcp   LISTEN 0      4096         0.0.0.0:111        0.0.0.0:*    users:(("rpcbind",pid=53292,fd=4),("systemd",pid=1,fd=55))
tcp   LISTEN 0      64              [::]:2049          [::]:*
tcp   LISTEN 0      4096            [::]:111           [::]:*    users:(("rpcbind",pid=53292,fd=6),("systemd",pid=1,fd=57))
```
3. Создаем директорию и настраиваем ее

```
user@debian:~$ mkdir -p /tmp/share/upload
user@debian:~$ sudo chown -R nobody:nogroup /tmp/share/
user@debian:~$ sudo chmod 0777 /tmp/share/upload/
```
4. Прописываем в `/etc/exports` настройки доступа к созданной директории

```
root@debian:/home/user# echo "/tmp/share/ 192.168.1.0/24(rw,sync,root_squash)" >> /etc/exports
...
user@debian:~$ cat /etc/exports
# /etc/exports: the access control list for filesystems which may be exported
#               to NFS clients.  See exports(5).
#
# Example for NFSv2 and NFSv3:
# /srv/homes       hostname1(rw,sync,no_subtree_check) hostname2(ro,sync,no_subtree_check)
#
# Example for NFSv4:
# /srv/nfs4        gss/krb5i(rw,sync,fsid=0,crossmnt,no_subtree_check)
# /srv/nfs4/homes  gss/krb5i(rw,sync,no_subtree_check)
#
/tmp/share/ 192.168.1.0/24(rw,sync,root_squash)
```
5. Экспортируем нашу директорию и проверяем ее

```
user@debian:~$ sudo exportfs -r
exportfs: /etc/exports [1]: Neither 'subtree_check' or 'no_subtree_check' specified for export "192.168.1.0/24:/tmp/share/".
  Assuming default behaviour ('no_subtree_check').
  NOTE: this default has changed since nfs-utils version 1.0.x

user@debian:~$ sudo exportfs -s
/tmp/share  192.168.1.0/24(sync,wdelay,hide,no_subtree_check,sec=sys,rw,secure,root_squash,no_all_squash)
```
6. Переходим к работе с клиентом. Устанавливаем клиентский пакет `nfs`

```
user@devdeb:~$ sudo apt install nfs-common -y
```
7. Добавляем строку в `/etc/fstab` и перезагружаем

```
root@devdeb:/home/user# echo "192.168.1.109:/tmp/share/ /mnt nfs vers=3,noauto,x-systemd.automount 0 0" >> /etc/fstab
user@devdeb:~$ sudo systemctl daemon-reload
user@devdeb:~$ sudo systemctl restart remote-fs.target
user@devdeb:~$ sudo mount | grep nfs
192.168.1.109:/tmp/share/ on /mnt type nfs (rw,relatime,vers=3,rsize=524288,wsize=524288,namlen=255,hard,proto=tcp,timeo=600,retrans=2,sec=sys,mountaddr=192.168.1.109,mountvers=3,mountport=49842,mountproto=udp,local_lock=none,addr=192.168.1.109)
user@devdeb:~$ sudo showmount -e 192.168.1.109
Export list for 192.168.1.109:
/tmp/share 192.168.1.0/24
```
8. Создаем пустой файл на сервере

```
user@debian:/tmp/share/upload$ touch nfs_test.txt
```
9. На клиенте проверяем, что мы видим этот файл

```
user@devdeb:/mnt/upload$ ls -l
total 0
-rw-r--r-- 1 user user 0 Oct 24 00:35 nfs_test.txt
```
10. Запишем строку в файл на клиенте

```
user@devdeb:/mnt/upload$ echo "Hello my first NFS folder! It's me from $(hostname) :)" >> nfs_test.txt
```
11. Проверим на сервере

```
user@debian:/tmp/share/upload$ cat nfs_test.txt
Hello my first NFS folder! It's me from devdeb :)
```
12. Пишем [`bash`-скрипт для автоматизации настройки серверной машины](./nfss_script.sh)

13. Пишем [`bash`-скрипт для автоматизации настройки клиентской машины](./nfsc_script.sh)