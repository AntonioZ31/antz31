# Службы. SystemD

## Написать сервис, который будет раз в 30 секунд мониторить лог на предмет наличия ключевого слова.

Создаём файл /etc/sysconfig/watchlog со следующим содержанием:

```
# Configuration file for my watchlog service
# Place it to /etc/sysconfig

# File and word in that file that we will be monit
WORD="ALERT"
LOG=/var/log/watchlog.log
```

Создаём файл /var/log/watchlog.log с рандомно сгенеренным текстом и словом ALERT.

Создаём скрипт /opt/watchlog.sh со следующим содержимым:

```
#!/bin/bash

WORD=$1
LOG=$2
DATE=`date`

if grep $WORD $LOG &> /dev/null
then
logger "$DATE: I found word, Master!"
else
exit 0
fi
```

Добавляем права на исполнение файла командой:

```
chmod +x /opt/watchlog.sh
```

Создаём юнит для сервиса /etc/systemd/system/watchlog.service со следующим содержимым:

```
[Unit]
Description=My watchlog service

[Service]
Type=oneshot
EnvironmentFile=/etc/sysconfig/watchlog
ExecStart=/opt/watchlog.sh $WORD $LOG
```

Создаём юнит для таймера /etc/systemd/system/watchlog.timer со следующим содержимым:

```
[Unit]
Description=Run watchlog script every 30 second

[Timer]
# Run every 30 second
OnUnitActiveSec=30
Unit=watchlog.service

[Install]
WantedBy=multi-user.target
```

Стартуем сервис watchlog командой:

```
systemctl start watchlog
```

Проверяем:

```
tail -f /var/log/messages
```

## Из epel установить spawn-fcgi и переписать init-скрипт на unit-файл. 

Устанавливаем spawn-fcgi и необходимые для него пакеты:

```
yum install epel-release -y && yum install spawn-fcgi php php-cli
mod_fcgid httpd -y

y
y
```

Раскомментируем указанные ниже строки в файле /etc/sysconfig/spawn-fcgi:

```
SOCKET=/var/run/php-fcgi.sock
OPTIONS="-u apache -g apache -s $SOCKET -S -M 0600 -C 32 -F 1 /var/run/spawn-fcgi.pid -- /usr/bin/php-cgi"
```
Создаём юнит файл со следующим содержимым:

```
[Unit]
Description=Spawn-fcgi startup service by Otus
After=network.target

[Service]
Type=simple
PIDFile=/var/run/spawn-fcgi.pid
EnvironmentFile=/etc/sysconfig/spawn-fcgi
ExecStart=/usr/bin/spawn-fcgi -n $OPTIONS
KillMode=process

[Install]
WantedBy=multi-user.target
```

Запускаем и проверяем работу:

```
systemctl start spawn-fcgi

systemctl status spawn-fcgi
```

# Дополнить юнит-файл apache httpd возможностью запустить несколько инстансов сервера с разными конфигами

Добавляем указанную ниже строку для использования шаблона в конфигурации файла окружения /usr/lib/systemd/system/httpd.service:

```
EnvironmentFile=/etc/sysconfig/httpd-%I
```

Создаём файл окружения с опцией для запуска веб-сервера с конфигурационным файлом /etc/sysconfig/httpd-first:

```
OPTIONS=-f conf/first.conf
```
Создаём второй файл /etc/sysconfig/httpd-second с аналогичным содержимым:

```
OPTIONS=-f conf/second.conf
```

В папке /etc/httpd/conf создаём два конфига first.conf и second.conf и копируем в них содержимое конфига httpd.conf

Правим только второй конфиг, чтобы были такие опции:

```
PidFile /var/run/httpd-second.pid
Listen 8080
```

Запускаем оба инстанса и проверяем работу:

```
systemctl start httpd@first
systemctl start httpd@second
ss -tnulp | grep httpd
```
Видим, что слушаются порты 80 и 8080.
