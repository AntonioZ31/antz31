#!/bin/bash
cd /etc/yum.repos.d/

# Переключение на репозиторий stream
dnf --disablerepo '*' --enablerepo=extras swap centos-linux-repos centos-stream-repos
dnf distro-sync

sudo yum update
# Установка репозитория elrepo
sudo rpm --import https://www.elrepo.org/RPM-GPG-KEY-elrepo.org
sudo yum install https://www.elrepo.org/elrepo-release-8.el8.elrepo.noarch.rpm -y
# Установка нового ядра
sudo yum --enablerepo elrepo-kernel install kernel-ml -y

# Обновление параметров GRUB
grub2-mkconfig -o /boot/grub2/grub.cfg
echo 'vagrant' | sudo -S -E bash grub2-set-default 0
echo "Grub update done."
# Перезагрузка ВМ
shutdown -r now
