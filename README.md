# Vagrant-стенд для обновления ядра и создания образа системы

## 1) Обновить ядро ОС из репозитория ELRepo

Включаем VPN.

Создаём Vagrantfile для создания виртуальной машины с ОС CentOS 8 на основе бокса centos/8 версии 4.2.16, т.к. скачать Stream 8 невозможно (ошибка 404). Машина будет с 2-мя ядрами CPU и 1ГБ ОЗУ.

Используя Vagrant версии 2.3.6, запускаем виртуальную машину командой:

```
vagrant up  
```

Отключаем VPN

Подключаемся к машине по SSH и смотрим текущую версию ядра:

```
vagrant ssh
uname -msr
#=> Linux 4.18.0-348.7.1.el8_5.x86_64 x86_64
```
Обновление CentOS 8 из официального проекта не поддерживается с декабря 2021, поэтому меняем зеркала на vault.centos.org:
```
cd /etc/yum.repos.d/
sed -i 's/mirrorlist/#mirrorlist/g' /etc/yum.repos.d/CentOS-*
sed -i 's|#baseurl=http://mirror.centos.org|baseurl=http://vault.centos.org|g' /etc/yum.repos.d/CentOS-*
```
Обновляем систему перед обновлением ядра:
```
sudo yum update
```
Перезапускаем систему, снова подключаемся по SSH:
```
sudo shutdown -r now
vagrant ssh
```
Устанавливаем репозиторий ElRepo, где хранится последняя версия ядра:
```
rpm --import https://www.elrepo.org/RPM-GPG-KEY-elrepo.org
```
