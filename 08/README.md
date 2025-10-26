## Домашнее задание

### `Systemd` - создание `unit`-файла
#### Задание

- написать `service`, который будет раз в 30 секунд мониторить лог на предмет наличия ключевого слова (файл лога и ключевое слово должны задаваться в `/etc/default`)
- установить `spawn-fcgi` и создать `unit`-файл (`spawn-fcgi.sevice`) с помощью переделки `init`-скрипта
- доработать `unit`-файл `Nginx` (`nginx.service`) для запуска нескольких инстансов сервера с разными конфигурационными файлами одновременно

#### Отчет

##### Стенд

- Виртуальная машина с ОС `Debian 12`
- ОЗУ: 4 Гб
- ЦПУ: 2 ядра

##### Основное задание

1. В директории `/etc/default` создаем файл с конфигурацией для нашего будущего сервиса, который будет мониторить, когда же админ установит `tmux`
```
root@debian:~# cat /etc/default/tmux_watcher
WORD="status\\\s+installed\\\s+tmux"
LOG=/var/log/dpkg.log
```

2. Создаем скрипт, который будет проверять лог утилиты `dpkg` и даем ему права на исполнение
```
root@debian:~# cat tmux_watcher.sh
#!/bin/bash

WORD=$1
LOG=$2
DATE=`date`

if grep -E $WORD $LOG &> /dev/null
    then
        logger "$DATE: tmux was installed, admin!"
    else
        exit 0
fi
root@debian:~# chmod +x tmux_watcher.sh
root@debian:~# ls -la tmux_watcher.sh
-rwxr-xr-x 1 root root 161 Oct 26 19:47 tmux_watcher.sh
```

3. Создадим юнит для сервиса
```
root@debian:~# cat /etc/systemd/system/tmux_watcher.service
[Unit]
Description=Service to monitor when admin installed tmux

[Service]
Type=oneshot
EnvironmentFile=/etc/default/tmux_watcher
ExecStart=/opt/tmux_watcher.sh "$WORD" $LOG
```

4. Создадим юнит для таймера
```
root@debian:~# cat /etc/systemd/system/tmux_watcher.timer
[Unit]
Description=Run tmux_watcher script every 30 second

[Timer]
# Run every 30 second
OnUnitActiveSec=30
Unit=tmux_watcher.service

[Install]
WantedBy=multi-user.target
```

5. Запустим `tmux_watcher.timer`
```
root@debian:~# systemctl start tmux_watcher.timer
root@debian:~# systemctl status tmux_watcher.timer
● tmux_watcher.timer - Run tmux_watcher script every 30 second
     Loaded: loaded (/etc/systemd/system/tmux_watcher.timer; disabled; preset: enabled)
     Active: active (elapsed) since Sun 2025-10-26 19:55:04 MSK; 4s ago
    Trigger: n/a
   Triggers: ● tmux_watcher.service

Oct 26 19:55:04 debian systemd[1]: Started tmux_watcher.timer - Run tmux_watcher script every 30 second.
```

6. Убедимся в результате
```
root@debian:~# journalctl -e
...
Oct 26 20:22:04 debian systemd[1]: Started tmux_watcher.timer - Run tmux_watcher script every 30 second.
Oct 26 20:22:36 debian systemd[1]: Starting tmux_watcher.service - Service to monitor when admin installed tmux...
Oct 26 20:22:36 debian root[17582]: Sun Oct 26 08:22:36 PM MSK 2025: tmux was installed, admin!
Oct 26 20:22:36 debian systemd[1]: tmux_watcher.service: Deactivated successfully.
Oct 26 20:22:36 debian systemd[1]: Finished tmux_watcher.service - Service to monitor when admin installed tmux.
```

7. Устанавливаем spawn-fcgi и необходимые для него пакеты
```
root@debian:~# apt install spawn-fcgi php php-cgi php-cli apache2 libapache2-mod-fcgid -y
```

8. Скачиваем `init` скрипт
```
root@debian:~# curl -O https://gist.github.com/cea2k/1318020
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100  120k    0  120k    0     0   222k      0 --:--:-- --:--:-- --:--:--  221k
root@debian:~# ls
1318020  tmux_watcher.sh
```

9. Создаем файл конфигурации
```
root@debian:~# mkdir -p /etc/spawn-fcgi
root@debian:~# cat /etc/spawn-fcgi/fcgi.conf
# You must set some working options before the "spawn-fcgi" service will work.
# If SOCKET points to a file, then this file is cleaned up by the init script.
#
# See spawn-fcgi(1) for all possible options.
#
# Example :
SOCKET=/var/run/php-fcgi.sock
OPTIONS="-u www-data -g www-data -s $SOCKET -S -M 0600 -C 32 -F 1 -- /usr/bin/php-cgi"
```

10. Создаем `unit`-файл, запускаем сервис и убеждаемся, что все работает
```
systemctl daemon-reload
root@debian:~# cat /etc/systemd/system/spawn-fcgi.service
[Unit]
Description=Spawn-fcgi startup service by Otus
After=network.target

[Service]
Type=simple
PIDFile=/var/run/spawn-fcgi.pid
EnvironmentFile=/etc/spawn-fcgi/fcgi.conf
ExecStart=/usr/bin/spawn-fcgi -n $OPTIONS
KillMode=process

[Install]
WantedBy=multi-user.target
root@debian:~# systemctl daemon-reload
root@debian:~# systemctl start spawn-fcgi
root@debian:~# systemctl status spawn-fcgi
● spawn-fcgi.service - Spawn-fcgi startup service by Otus
     Loaded: loaded (/etc/systemd/system/spawn-fcgi.service; disabled; preset: enabled)
     Active: active (running) since Sun 2025-10-26 21:54:33 MSK; 8s ago
   Main PID: 36893 (php-cgi)
      Tasks: 33 (limit: 4652)
     Memory: 15.7M
        CPU: 18ms
     CGroup: /system.slice/spawn-fcgi.service
             ├─36893 /usr/bin/php-cgi
             ├─36896 /usr/bin/php-cgi
             ├─36897 /usr/bin/php-cgi
             ├─36898 /usr/bin/php-cgi
             ├─36899 /usr/bin/php-cgi
             ├─36900 /usr/bin/php-cgi
             ├─36901 /usr/bin/php-cgi
             ├─36902 /usr/bin/php-cgi
             ├─36903 /usr/bin/php-cgi
             ├─36904 /usr/bin/php-cgi
             ├─36905 /usr/bin/php-cgi
             ├─36906 /usr/bin/php-cgi
             ├─36907 /usr/bin/php-cgi
             ├─36908 /usr/bin/php-cgi
             ├─36909 /usr/bin/php-cgi
             ├─36910 /usr/bin/php-cgi
             ├─36911 /usr/bin/php-cgi
             ├─36912 /usr/bin/php-cgi
             ├─36913 /usr/bin/php-cgi
             ├─36914 /usr/bin/php-cgi
             ├─36915 /usr/bin/php-cgi
             ├─36916 /usr/bin/php-cgi
             ├─36917 /usr/bin/php-cgi
             ├─36918 /usr/bin/php-cgi
             ├─36919 /usr/bin/php-cgi
             ├─36920 /usr/bin/php-cgi
             ├─36921 /usr/bin/php-cgi
             ├─36922 /usr/bin/php-cgi
             ├─36923 /usr/bin/php-cgi
             ├─36924 /usr/bin/php-cgi
             ├─36925 /usr/bin/php-cgi
             ├─36926 /usr/bin/php-cgi
             └─36927 /usr/bin/php-cgi

Oct 26 21:54:33 debian systemd[1]: Started spawn-fcgi.service - Spawn-fcgi startup service by Otus.
```

11. Устанавливаем пакет `nginx`
```
root@debian:~# apt install nginx -y
```

12. Создадим новый `unit` файл для работы с шаблонами
```
root@debian:~# cat /etc/systemd/system/nginx@.service
# Stop dance for nginx
# =======================
#
# ExecStop sends SIGSTOP (graceful stop) to the nginx process.
# If, after 5s (--retry QUIT/5) nginx is still running, systemd takes control
# and sends SIGTERM (fast shutdown) to the main process.
# After another 5s (TimeoutStopSec=5), and if nginx is alive, systemd sends
# SIGKILL to all the remaining processes in the process group (KillMode=mixed).
#
# nginx signals reference doc:
# http://nginx.org/en/docs/control.html
#
[Unit]
Description=A high performance web server and a reverse proxy server
Documentation=man:nginx(8)
After=network.target nss-lookup.target

[Service]
Type=forking
PIDFile=/run/nginx-%I.pid
ExecStartPre=/usr/sbin/nginx -t -c /etc/nginx/nginx-%I.conf -q -g 'daemon on; master_process on;'
ExecStart=/usr/sbin/nginx -c /etc/nginx/nginx-%I.conf -g 'daemon on; master_process on;'
ExecReload=/usr/sbin/nginx -c /etc/nginx/nginx-%I.conf -g 'daemon on; master_process on;' -s reload
ExecStop=-/sbin/start-stop-daemon --quiet --stop --retry QUIT/5 --pidfile /run/nginx-%I.pid
TimeoutStopSec=5
KillMode=mixed

[Install]
WantedBy=multi-user.target
```

13. Создадим два файла конфигурации для запуска нескольких инстансов `nginx`
```
root@debian:/etc/nginx# cat nginx-first.conf
...
pid /run/nginx-first.pid;
...
        server {
                listen 9001;
        }
...
root@debian:/etc/nginx# cat nginx-second.conf
...
pid /run/nginx-second.pid;
...
        server {
                listen 9002;
        }
...
```

14. Запустим наши сервисы и проверим их работоспособность
```
root@debian:/etc/nginx# systemctl start nginx@first
root@debian:/etc/nginx# systemctl status nginx@first
● nginx@first.service - A high performance web server and a reverse proxy server
     Loaded: loaded (/etc/systemd/system/nginx@.service; disabled; preset: enabled)
     Active: active (running) since Sun 2025-10-26 22:06:19 MSK; 47s ago
       Docs: man:nginx(8)
...
root@debian:/etc/nginx# systemctl start nginx@second
root@debian:/etc/nginx# systemctl status nginx@second
● nginx@second.service - A high performance web server and a reverse proxy server
     Loaded: loaded (/etc/systemd/system/nginx@.service; disabled; preset: enabled)
     Active: active (running) since Sun 2025-10-26 22:07:14 MSK; 5s ago
       Docs: man:nginx(8)
...
root@debian:/etc/nginx# ss -tulnp | grep nginx
tcp   LISTEN 0      511          0.0.0.0:9001      0.0.0.0:*    users:(("nginx",pid=41504,fd=5),("nginx",pid=41503,fd=5),("nginx",pid=41502,fd=5))
tcp   LISTEN 0      511          0.0.0.0:9002      0.0.0.0:*    users:(("nginx",pid=41855,fd=5),("nginx",pid=41854,fd=5),("nginx",pid=41853,fd=5))
tcp   LISTEN 0      511          0.0.0.0:80        0.0.0.0:*    users:(("nginx",pid=37528,fd=5),("nginx",pid=37527,fd=5),("nginx",pid=37525,fd=5))
tcp   LISTEN 0      511             [::]:80           [::]:*    users:(("nginx",pid=37528,fd=6),("nginx",pid=37527,fd=6),("nginx",pid=37525,fd=6))
```
Все экземпляры `nginx` запустились и работают