## Домашнее задание

### Сборка `RPM`-пакета и создание репозитория
#### Задание

- создать свой `RPM`
- cоздать свой репозиторий и разместить там ранее собранный `RPM`

#### Отчет

##### Стенд

- Виртуальная машина с ОС `AlmaLinux 10`
- ОЗУ: 4 Гб
- ЦПУ: 2 ядра

##### Основное задание

1. Устанавливаем необходимые пакеты

```
root@localhost:~# yum install -y wget rpmdevtools rpm-build createrepo yum-utils cmake gcc git nano
```
2. Для сборки будем использовать пакет `nginx` и соберем его с дополнитльным модулем `ngx_broli`, как в методическом материале. Создадим папку для работы и загрузим пакет `nginx` с исходным кодом

```
root@localhost:~# mkdir rpm && cd rpm
root@localhost:~/rpm# yumdownloader --source nginx
подключение репозитория appstream-source
подключение репозитория baseos-source
подключение репозитория crb-source
подключение репозитория extras-source
AlmaLinux 10 - AppStream - Source                                                  ...
```
3. Установим наш пакет
```
root@localhost:~/rpm# rpm -Uvh nginx*.src.rpm
Обновление / установка...
   1:nginx-2:1.26.3-1.el10            ################################# [100%]

```

4. Как видно, в домашней директории создались каталоги для сборки
```
root@localhost:~/rpm# ls ../rpmbuild/
SOURCES  SPECS
```

5. Также установим все зависимости для сборки пакетв `nginx`
```
root@localhost:~/rpm# yum-builddep nginx
подключение репозитория appstream-source
подключение репозитория baseos-source
подключение репозитория crb-source
подключение репозитория extras-source
Последняя проверка окончания срока действия метаданных: 0:02:08 назад, Сб 25 окт 2025 17:26:13.
Пакет make-1:4.4.1-9.el10.x86_64 уже установлен.
Пакет gcc-14.2.1-7.el10.alma.1.x86_64 уже установлен.
Пакет systemd-rpm-macros-257-9.el10_0.1.alma.1.noarch уже установлен.
Пакет systemd-257-9.el10_0.1.alma.1.x86_64 уже установлен.
Пакет gnupg2-2.4.5-2.el10.x86_64 уже установлен.
Зависимости разрешены.
...
```

6. Скачиваем исходный код модуля `ngx_brotli`

```
root@localhost:~# cd ~
root@localhost:~# git clone --recurse-submodules -j8 https://github.com/google/ngx_brotli
Клонирование в «ngx_brotli»...
...
root@localhost:~# cd ngx_brotli/deps/brotli
root@localhost:~/ngx_brotli/deps/brotli# mkdir out && cd out
```

7. Соберем модуль `ngx_brotli`
```
root@localhost:~/ngx_brotli/deps/brotli/out# cmake -DCMAKE_BUILD_TYPE=Release -DBUILD_SHARED_LIBS=OFF -DCMAKE_C_FLAGS="-Ofast -m64 -march=native -mtune=native -flto -funroll-loops -ffunction-sections -fdata-sections -Wl,--gc-sections" -DCMAKE_CXX_FLAGS="-Ofast -m64 -march=native -mtune=native -flto -funroll-loops -ffunction-sections -fdata-sections -Wl,--gc-sections" -DCMAKE_INSTALL_PREFIX=./installed ..
...
-- Build files have been written to: /root/ngx_brotli/deps/brotli/out
root@localhost:~/ngx_brotli/deps/brotli/out# cmake --build . --config Release -j 2 --target brotlienc
...
[100%] Built target brotlienc
root@localhost:~# cd ~
```

8. Изменяем `SPEC` файл, добавляя нужную строку (файл лежит в `/root/rpmbuild/SPECS/nginx.spec`)
```
if ! ./configure \
    --add-module=/root/ngx_brotli \
    --prefix=%{_datadir}/nginx \
    --sbin-path=%{_sbindir}/nginx \
    --modules-path=%{nginx_moduledir} \
    --conf-path=%{_sysconfdir}/nginx/nginx.conf \
    --error-log-path=%{_localstatedir}/log/nginx/error.log \
    --http-log-path=%{_localstatedir}/log/nginx/access.log \
    --http-client-body-temp-path=%{_localstatedir}/lib/nginx/tmp/client_body \
```

9. Собираем пакет
```
root@localhost:~/rpmbuild/SPECS# rpmbuild -ba nginx.spec -D 'debug_package %{nil}'
...
Выполняется(%clean): /bin/sh -e /var/tmp/rpm-tmp.Po0GvS
+ umask 022
+ cd /root/rpmbuild/BUILD
+ cd nginx-1.26.3
+ /usr/bin/rm -rf /root/rpmbuild/BUILDROOT/nginx-1.26.3-1.el10.x86_64
+ RPM_EC=0
++ jobs -p
+ exit 0
Выполняется(rmbuild): /bin/sh -e /var/tmp/rpm-tmp.cL0IVH
+ umask 022
+ cd /root/rpmbuild/BUILD
+ rm -rf /root/rpmbuild/BUILD/nginx-1.26.3-SPECPARTS
+ rm -rf nginx-1.26.3 nginx-1.26.3.gemspec
+ RPM_EC=0
++ jobs -p
+ exit 0
```

10. Убедимся, что пакеты создались
```
root@localhost:~/rpmbuild# ls RPMS/x86_64/
nginx-1.26.3-1.el10.x86_64.rpm       nginx-mod-devel-1.26.3-1.el10.x86_64.rpm              nginx-mod-http-perl-1.26.3-1.el10.x86_64.rpm         nginx-mod-mail-1.26.3-1.el10.x86_64.rpm
nginx-core-1.26.3-1.el10.x86_64.rpm  nginx-mod-http-image-filter-1.26.3-1.el10.x86_64.rpm  nginx-mod-http-xslt-filter-1.26.3-1.el10.x86_64.rpm  nginx-mod-stream-1.26.3-1.el10.x86_64.rpm
```

11. Копируем файлы из каталога `noarch` в папку с другими пакетами и переходим в нее
```
root@localhost:~/rpmbuild/RPMS# cp noarch/* x86_64/
root@localhost:~/rpmbuild/RPMS# cd x86_64/
```

12. Установим наши пакеты и убедимся, что все работает
```
root@localhost:~/rpmbuild/RPMS/x86_64# yum localinstall *.rpm
...
root@localhost:~/rpmbuild/RPMS/x86_64# systemctl start nginx
root@localhost:~/rpmbuild/RPMS/x86_64# systemctl status nginx
● nginx.service - The nginx HTTP and reverse proxy server
     Loaded: loaded (/usr/lib/systemd/system/nginx.service; disabled; preset: disabled)
     Active: active (running) since Sat 2025-10-25 17:55:44 MSK; 5s ago
 Invocation: 442a9449cf734c2095de5bbb2229136a
    Process: 32725 ExecStartPre=/usr/bin/rm -f /run/nginx.pid (code=exited, status=0/SUCCESS)
    Process: 32727 ExecStartPre=/usr/sbin/nginx -t (code=exited, status=0/SUCCESS)
    Process: 32729 ExecStart=/usr/sbin/nginx (code=exited, status=0/SUCCESS)
   Main PID: 32730 (nginx)
      Tasks: 3 (limit: 23132)
     Memory: 4.9M (peak: 5M)
        CPU: 34ms
     CGroup: /system.slice/nginx.service
             ├─32730 "nginx: master process /usr/sbin/nginx"
             ├─32731 "nginx: worker process"
             └─32733 "nginx: worker process"

окт 25 17:55:44 localhost.localdomain systemd[1]: Starting nginx.service - The nginx HTTP and reverse proxy server...
окт 25 17:55:44 localhost.localdomain nginx[32727]: nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
окт 25 17:55:44 localhost.localdomain nginx[32727]: nginx: configuration file /etc/nginx/nginx.conf test is successful
окт 25 17:55:44 localhost.localdomain systemd[1]: Started nginx.service - The nginx HTTP and reverse proxy server.
```

13. Создаем каталог, где будем хранить наши пакеты для `nginx`, копируем их туда и в той же директории инициализируем репозиторий
```
root@localhost:~# mkdir /usr/share/nginx/html/repo
root@localhost:~# cp rpmbuild/RPMS/x86_64/* /usr/share/nginx/html/repo/
root@localhost:~# createrepo /usr/share/nginx/html/repo/
Directory walk started
Directory walk done - 10 packages
Temporary output repo path: /usr/share/nginx/html/repo/.repodata/
Pool started (with 5 workers)
Pool finished
```

14. Настраиваем `nginx` и проверяем корректность конфигурации, перезапускаем `nginx` 
```
root@localhost:~# nano /etc/nginx/nginx.conf
...
    server {
        listen       80;
        listen       [::]:80;
        server_name  _;
        root         /usr/share/nginx/html;
        index index.html index.htm;
        autoindex on;

        # Load configuration files for the default server block.
        include /etc/nginx/default.d/*.conf;
    }
...
root@localhost:~# nginx -t
nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
nginx: configuration file /etc/nginx/nginx.conf test is successful
root@localhost:~# nginx -s reload
```

15. Проверим, что веб-сервер действительно работает
```
root@localhost:~# curl -a http://localhost/repo/
<html>
<head><title>Index of /repo/</title></head>
<body>
<h1>Index of /repo/</h1><hr><pre><a href="../">../</a>
<a href="repodata/">repodata/</a>                                          25-Oct-2025 15:13                   -
<a href="nginx-1.26.3-1.el10.x86_64.rpm">nginx-1.26.3-1.el10.x86_64.rpm</a>                     25-Oct-2025 15:00               33138
<a href="nginx-all-modules-1.26.3-1.el10.noarch.rpm">nginx-all-modules-1.26.3-1.el10.noarch.rpm</a>         25-Oct-2025 15:00                9553
<a href="nginx-core-1.26.3-1.el10.x86_64.rpm">nginx-core-1.26.3-1.el10.x86_64.rpm</a>                25-Oct-2025 15:00             1157538
<a href="nginx-filesystem-1.26.3-1.el10.noarch.rpm">nginx-filesystem-1.26.3-1.el10.noarch.rpm</a>          25-Oct-2025 15:00               11299
<a href="nginx-mod-devel-1.26.3-1.el10.x86_64.rpm">nginx-mod-devel-1.26.3-1.el10.x86_64.rpm</a>           25-Oct-2025 15:00              897031
<a href="nginx-mod-http-image-filter-1.26.3-1.el10.x86_64.rpm">nginx-mod-http-image-filter-1.26.3-1.el10.x86_6..&gt;</a> 25-Oct-2025 15:00               21555
<a href="nginx-mod-http-perl-1.26.3-1.el10.x86_64.rpm">nginx-mod-http-perl-1.26.3-1.el10.x86_64.rpm</a>       25-Oct-2025 15:00               33563
<a href="nginx-mod-http-xslt-filter-1.26.3-1.el10.x86_64.rpm">nginx-mod-http-xslt-filter-1.26.3-1.el10.x86_64..&gt;</a> 25-Oct-2025 15:00               20407
<a href="nginx-mod-mail-1.26.3-1.el10.x86_64.rpm">nginx-mod-mail-1.26.3-1.el10.x86_64.rpm</a>            25-Oct-2025 15:00               55329
<a href="nginx-mod-stream-1.26.3-1.el10.x86_64.rpm">nginx-mod-stream-1.26.3-1.el10.x86_64.rpm</a>          25-Oct-2025 15:00               88809
<a href="percona-release-latest.noarch.rpm">percona-release-latest.noarch.rpm</a>                  21-Aug-2025 12:37               28532
</pre><hr></body>
</html>

```

16. Добавим наш репозиторий в `/etc/yum.repos.d` и убедимся в его подключении
```
root@localhost:/usr/share/nginx/html# cat >> /etc/yum.repos.d/otus.repo << EOF
[otus]
name=otus-linux
baseurl=http://localhost/repo
gpgcheck=0
enabled=1
EOF
root@localhost:/usr/share/nginx/html# yum repolist enabled | grep otus
otus                                     otus-linux
root@localhost:/usr/share/nginx/html#

```

17. Вернемся в директорию с репозиторием и добавим туда другой пакет
```
root@localhost:/usr/share/nginx/html# cd /usr/share/nginx/html/repo/
root@localhost:/usr/share/nginx/html/repo# wget https://repo.percona.com/yum/percona-release-latest.noarch.rpm
...
```

18. Обновим список пакетов в репозитории
```
root@localhost:/usr/share/nginx/html/repo# createrepo /usr/share/nginx/html/repo/
Directory walk started
Directory walk done - 11 packages
Temporary output repo path: /usr/share/nginx/html/repo/.repodata/
Pool started (with 5 workers)
Pool finished
root@localhost:/usr/share/nginx/html/repo# yum makecache
...
otus-linux                                                                                                 626 kB/s | 3.0 kB     00:00
Создан кэш метаданных.
root@localhost:/usr/share/nginx/html/repo# yum list | grep otus
percona-release.noarch                                 1.0-32                             otus
```

19. Установим пакет, которые только добавили в репозиторий
```
root@localhost:/usr/share/nginx/html/repo# yum install -y percona-release.noarch
...
Установлен:
  percona-release-1.0-32.noarch

Выполнено!
```