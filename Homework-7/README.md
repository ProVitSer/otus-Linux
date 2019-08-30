# **Загрузка системы**
1. Попасть в систему без пароля несколькими способами
2. Установить систему с LVM, после чего переименовать VG
3. Добавить модуль в initrd

------------

# **Задание 1 Способо 1**

При запуске системы нажимаем e, и переходим в режим редавтирования

![alt text](https://github.com/ProVitSer/otus-Linux/blob/master/Homework-7/images/1.png)

Из параметров grub найти строку , которая начинается с linux16, находим ro, и заменяем его на rw init=/sysroot/bin/sh
![alt text](https://github.com/ProVitSer/otus-Linux/blob/master/Homework-7/images/2.png)

Далее выходим нажав комбинацию Ctrl+X и входим в emergency режим, и вводим следующую команду

![alt text](https://github.com/ProVitSer/otus-Linux/blob/master/Homework-7/images/3.png)

```bash
chroot /sysroot/
```
И меняем пароль от root с помощью команды 

```bash
passwd root
```

После этого, обновляем параметры SELinux  с помощью команды 
```bash
touch /.autorelable
```

![alt text](https://github.com/ProVitSer/otus-Linux/blob/master/Homework-7/images/4.png)

После этого нужно перезапустить сервер с помощью команды reboot -f и зайти в систему под новым паролем

![alt text](https://github.com/ProVitSer/otus-Linux/blob/master/Homework-7/images/5.png)



# **Задание 1 Способо 2**

При запуске системы нажимаем e, и переходим в режим редавтирования

![alt text](https://github.com/ProVitSer/otus-Linux/blob/master/Homework-7/images/1-1.png)

Из параметров grub найти строку, которая начинается с linux16, перейти в самый конец и добавить rd.break
Далее выходим нажав комбинацию Ctrl+X и входим в emergency режим. На данном этапе корневая фаловая система монтируется в режиме только на чтение в /sysroot и должна быть перемонтирована с разрешением на чтение/хапись, чтобы мы могли вносить изменения. Для этого выполняем следующу команду

```bash
mount -o remount,rw /sysroot
```

![alt text](https://github.com/ProVitSer/otus-Linux/blob/master/Homework-7/images/1-3.png)


После того как файловая система была пермонтирована выполняем комнаду 

```bash
chroot /sysroot
```
![alt text](https://github.com/ProVitSer/otus-Linux/blob/master/Homework-7/images/1-4.png)

И меняем пароль от root с помощью команды 

```bash
passwd root
```
После этого, обновляем параметры SELinux  с помощью команды 

```bash
touch /.autorelable
```
![alt text](https://github.com/ProVitSer/otus-Linux/blob/master/Homework-7/images/1-5.png)

После этого нужно перезапустить сервер с помощью команды reboot -f и зайти в систему под новым паролем

![alt text](https://github.com/ProVitSer/otus-Linux/blob/master/Homework-7/images/1-6.png)


# **Итог 1 задания**

Отличе первого способо от второго в том, что первый изменяет процесс с которого стартует ядро, а второй использует прерывания процесса до загрузки


# **Задание 2**

Смотрим список блочных устройств и VG

```bash
[root@repo ~]# vgs
  VG         #PV #LV #SN Attr   VSize   VFree
  VolGroup00   1   2   0 wz--n- <38.97g    0 
[root@repo ~]# lsblk 
NAME                    MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
sda                       8:0    0   40G  0 disk 
├─sda1                    8:1    0    1M  0 part 
├─sda2                    8:2    0    1G  0 part /boot
└─sda3                    8:3    0   39G  0 part 
  ├─VolGroup00-LogVol00 253:0    0 37.5G  0 lvm  /
  └─VolGroup00-LogVol01 253:1    0  1.5G  0 lvm  [SWAP]
```

Переименовываем VG
```bash
[root@repo ~]# vgrename VolGroup00 Otus
  Volume group "VolGroup00" successfully renamed to "Otus"
```

Проверяем
```bash
[root@repo ~]# vgs
  VG   #PV #LV #SN Attr   VSize   VFree
  Otus   1   2   0 wz--n- <38.97g    0 
```

Изменяем старое значение на новое
```bash
[root@repo ~]# sed -i 's/VolGroup00/Otus/g' /etc/fstab 
[root@repo ~]# sed -i 's/VolGroup00/Otus/g' /boot/grub2/grub.cfg 
[root@repo ~]# sed -i 's/VolGroup00/Otus/g' /etc/default/grub 
```

Перезагружаемся, и после перезагрузки проверяем
```bash
[root@repo ~]# lsblk 
NAME              MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
sda                 8:0    0   40G  0 disk 
├─sda1              8:1    0    1M  0 part 
├─sda2              8:2    0    1G  0 part /boot
└─sda3              8:3    0   39G  0 part 
  ├─Otus-LogVol00 253:0    0 37.5G  0 lvm  /
  └─Otus-LogVol01 253:1    0  1.5G  0 lvm  [SWAP]
[root@repo ~]# vgs
  VG   #PV #LV #SN Attr   VSize   VFree
  Otus   1   2   0 wz--n- <38.97g    0 
```

# **Задание 3**

Первым делом создадим папку для custom скриптов
```bash
[root@repo ~]# mkdir /usr/lib/dracut/modules.d/01print
```

Добавляем наши скрипты
```bash
[root@repo ~]# cat << EOF > /usr/lib/dracut/modules.d/01print/pinguin.sh
> #!/bin/bash
> exec 0<>/dev/console 1<>/dev/console 2<>/dev/console
> cat <<'msgend' 
> _______________________
> < I'm dracut module  >
>  -----------------------
>    \
>     \
>         .--.
>        |o_o |
>        |:_/ |
>       //   \ \
>      (|     | )
>     /'\_   _/'\
>     \___)=(___/
> 
> msgend
> sleep 10
> echo " continuing.... 
> EOF
```
```bash
[root@repo ~]# cat << EOF > /usr/lib/dracut/modules.d/01print/module-setup.sh
> #!/bin/bash
> check() {
>  return 0
> }
> depends() {
>  return 0
> }
> install() {
>  inst_hook cleanup 00 "${moddir}/pinguin.sh"
> } 
> EOF
```

Пересобираем initrd
```bash
[root@repo ~]# dracut -f -v
Executing: /sbin/dracut -f -v
dracut module 'busybox' will not be installed, because command 'busybox' could not be found!
dracut module 'crypt' will not be installed, because command 'cryptsetup' could not be found!
dracut module 'dmraid' will not be installed, because command 'dmraid' could not be found!
dracut module 'dmsquash-live-ntfs' will not be installed, because command 'ntfs-3g' could not be found!
*** Generating early-microcode cpio image contents ***
*** No early-microcode cpio image needed ***
*** Store current command line parameters ***
*** Creating image file ***
*** Creating image file done ***
*** Creating initramfs image file '/boot/initramfs-3.10.0-862.2.3.el7.x86_64.img' done ***
```

Проверяем
```bash
[root@repo ~]# lsinitrd -m /boot/initramfs-3.10.0-862.2.3.el7.x86_64.img 
Image: /boot/initramfs-3.10.0-862.2.3.el7.x86_64.img: 14M
========================================================================
Version: dracut-033-535.el7

dracut modules:
bash
print
nss-softokn
i18n
drm
plymouth
dm
kernel-modules
lvm
qemu
resume
rootfs-block
terminfo
udev-rules
biosdevname
systemd
usrmount
base
fs-lib
shutdown
========================================================================
```

Перезагружаемся

![alt text](https://github.com/ProVitSer/otus-Linux/blob/master/Homework-7/images/3-1.png)
