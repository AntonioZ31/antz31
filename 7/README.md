# 7. Загрузка системы.

## Попасть в систему без пароля несколькими способами.

Способ 1. init=/bin/sh

Открываем GUI VirtualBox, запускаем виртуальную машину и при выборе ядра для загрузки нажимаем e. Добавляем в конец строки, которая начинается на linux:

```
init=/bin/sh
```
Нажимаем CTRL+X, перемонтируем каталог root в режим Read-Write.
```
mount -o remount,rw /
```
Проверяем, создав файл в директории root или так:
```
mount | grep root
```

Способ 2. rd.break

Первый шаг аналогичен 1 способу, только добавляем rd.break, попадаем в emergency mode. Выполняем команды:

```
mount -o remount,rw /sysroot
chroot /sysroot
passwd root
touch /.autorelabel
```
Перезагружаем ВМ.

Способ 3. rw init=/sysroot/bin/sh

Первый шаг аналогичен 1 способу, но мы заменяем ro на rw init=/sysroot/bin/sh

Файловая система уже в Read-Write, поэтому мы могли бы сразу заменить пароль, но в режиме emergency утилита passwd недоступна.

Возможное решение - отредактировать файл /sysroot/etc/passwd так, чтобы пароль был пустым, и задать его при первом входе в систему под root в нормальном режиме. В файле оставляем удаляем значок маски "x", получаем строку: 

```
root::0:root:/root:/sysroot/bin/bash
```

## Установить систему с LVM, после чего переименовать VG.

Смотрим текущее состояние системы:

```
vgs 

VG          #PV #LV #SN Attr   VSize    VFree
  cs_centos8s   1   2   0 wz--n- <127.00g    0
```
Далее по методичке выполняем команды:

```
sudo -i
vgrename cs_centos8s OtusRoot
vi /etc/fstab
vi /etc/default/grub
vi /boot/grub2/grub.cfg
mkinitrd -f -v /boot/initramfs-$(uname -r).img $(uname -r)
logout
exit
vagrant reload
vagrant ssh
sudo -i
vgs
```
## Добавить модуль в initrd

```
sudo -i
mkdir /usr/lib/dracut/modules.d/01test
cd /usr/lib/dracut/modules.d/01test
touch module-setup.sh
touch test.sh
mc
mkinitrd -f -v /boot/initramfs-$(uname -r).img $(uname -r)
lsinitrd -m /boot/initramfs-$(uname -r).img | grep test
vim /boot/grub2/grub.cfg
```

