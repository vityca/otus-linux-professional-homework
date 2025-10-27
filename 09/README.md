## Домашнее задание

### Пишем скрипт
#### Задание

- написать скрипт для `CRON`, который раз в час будет формировать письмо и отправлять на заданную почту

#### Отчет

##### Стенд

- Виртуальная машина с ОС `Debian 12`
- ОЗУ: 4 Гб
- ЦПУ: 2 ядра

##### Основное задание

1. Пишем сам [скрипт](./files/monitoring.sh), который и будет производить всю работу
2. Пишем для него [файл конфигурации](./files/monitoring.conf), в котором можно будет указать название файла с логом, который мы будем анализировать, файл со временем последнего запуска скрипта и сам файл почты, в который мы записываем все данные, получаемые в процессе выполнения скрипта

```
user@debian:~/task9$ cat monitoring.conf
LOG_FILE=/home/user/task9/access-4560-644067.log
LAST_START_FILE=/home/user/task9/.latest_start_time.time
MAIL_FILE=/home/user/task9/.mail.tmp
```
3. Добавляем строку в файл `/etc/crontab` и перезапускаем службу

```
user@debian:~/task9$ cat /etc/crontab
...
0 * * * *      user    /bin/bash /home/user/task9/monitoring.sh
user@debian:~/task9$ sudo systemctl restart cron.service
```