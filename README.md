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
Исправляем репозиторий, переключаясь на centos-stream-repos:
```
dnf --disablerepo '*' --enablerepo=extras swap centos-linux-repos centos-stream-repos
dnf distro-sync
```
Сначала пробовал идти таким путём, но он скорее всего неграмотный, т.к. просто ссылается на архивный репозиторий:
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
Устанавливаем репозиторий ElRepo, где хранится последняя версия ядра. Импортируем ключ репозитория:
```
sudo rpm --import https://www.elrepo.org/RPM-GPG-KEY-elrepo.org
```
Устанавливаем сам репозиторий для RHEL-8 и CentOS 8:
```
sudo yum install https://www.elrepo.org/elrepo-release-8.el8.elrepo.noarch.rpm -y
```
Устанавливаем новое ядро из репозитория elrepo-kernel командой:
```
sudo yum --enablerepo elrepo-kernel install kernel-ml -y
```
Меняем конфиг GRUB:
```
vi /etc/default/grub
GRUB_DEFAULT=0
```
Ребутаем машину, снова подключаемся:
```
reboot
vagrant ssh
```
Проверяем версию ядра:
```
uname -msr
#=> Linux 6.3.5-1.el8.elrepo.x86_64 x86_64
```

## 2) Создать Vagrant box c помощью Packer

Создаём следующую структуру каталогов в проекте:
```bash
packer/
├── centos.json
├── http
│   └── ks.cfg
├── scripts
│   ├── stage-1-kernel-update.sh
│   └── stage-2-clean.sh
```
Исправляем опечатки в файле centos.json, изменяем способ пробрасывания пароля sudo в разделе provisioners, изменив значение execute_command. Изменяем ssh_timeout до 30 минут.

Находим в сети репозитории с CentOS Stream 8, заменяем в файле centos .json контрольную сумму и URL до iso образа.

Заменяем содержимое файла stage-1-kernel-update.sh, т.е. то что в методичке заменяем на то, что получили в первом пункте задания.

В разделе vboxmanage прописываем команду modifyvm с параметром --natpf1, т.к. у меня очень странный баг с VirtualBox, из-за которого при попытке собрать образ с помощью Packer версия VirtualBox каждый раз откатывалась до 6.1, хотя я устанавливал 7.0. В итоге не получилось воспользоваться параметром --nat-localhostreachable1. В итоге команда выглядела так:
```
[ "modifyvm", "{{.Name}}", "--natpf1", "guestssh,tcp,,2222,,22" ]
```
