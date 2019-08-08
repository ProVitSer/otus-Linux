# **Работа с LVM**
На имеющемся образе /dev/mapper/VolGroup00-LogVol00 38G 738M 37G 2% /

уменьшить том под / до 8G
выделить том под /home
выделить том под /var
/var - сделать в mirror
/home - сделать том для снэпшотов
прописать монтирование в fstab
попробовать с разными опциями и разными файловыми системами ( на выбор)
- сгенерить файлы в /home/
- снять снэпшот
- удалить часть файлов
- восстановится со снэпшота

* на нашей куче дисков попробовать поставить btrfs/zfs - с кешем, снэпшотами - разметить здесь каталог /opt


------------



Установим xfsdump:
```bash
[root@lvm ~]# yum install xfsdump -y
```


```bash
[root@lvm ~]# lsblk 
NAME                    MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
sda                       8:0    0   40G  0 disk 
├─sda1                    8:1    0    1M  0 part 
├─sda2                    8:2    0    1G  0 part /boot
└─sda3                    8:3    0   39G  0 part 
  ├─VolGroup00-LogVol00 253:0    0 37.5G  0 lvm  /
  └─VolGroup00-LogVol01 253:1    0  1.5G  0 lvm  [SWAP]
sdb                       8:16   0   10G  0 disk 
sdc                       8:32   0    2G  0 disk 
sdd                       8:48   0    1G  0 disk 
sde                       8:64   0    1G  0 disk 
```

Создаем физические тома для / и под зеркало /var:
```bash
[root@lvm ~]# pvcreate /dev/sd{b,c,e}
 Physical volume "/dev/sdb" successfully created.
  Physical volume "/dev/sdc" successfully created.
  Physical volume "/dev/sde" successfully created.
```

Подготовим временный том для / раздела:
```bash
[root@lvm ~]# vgcreate vg_root /dev/sdb
  Volume group "vg_root" successfully created
[root@lvm ~]# lvcreate -n lv_root -l +100%FREE /dev/vg_root
  Logical volume "lv_root" created.
```

Создаем файловую систему и монтируем её для переноса данных из действующего "/" раздела:
```bash
[root@lvm ~]# mkfs.xfs /dev/vg_root/lv_root
meta-data=/dev/vg_root/lv_root   isize=512    agcount=4, agsize=655104 blks
         =                       sectsz=512   attr=2, projid32bit=1
         =                       crc=1        finobt=0, sparse=0
data     =                       bsize=4096   blocks=2620416, imaxpct=25
         =                       sunit=0      swidth=0 blks
naming   =version 2              bsize=4096   ascii-ci=0 ftype=1
log      =internal log           bsize=4096   blocks=2560, version=2
         =                       sectsz=512   sunit=0 blks, lazy-count=1
realtime =none                   extsz=4096   blocks=0, rtextents=0
[root@lvm ~]# mount /dev/vg_root/lv_root /mnt
```

Копируем все данные с "/" раздела в примонтированный /mnt:
```bash
[root@lvm ~]# xfsdump -J - /dev/VolGroup00/LogVol00 | xfsrestore -J - /mnt
***************************************
xfsdump: media file size 741540304 bytes
xfsdump: dump size (non-dir files) : 728381256 bytes
xfsdump: dump complete: 16 seconds elapsed
xfsdump: Dump Status: SUCCESS
xfsrestore: restore complete: 16 seconds elapsed
xfsrestore: Restore Status: SUCCESS
```

```bash
[root@lvm ~]# ll /mnt
total 12
lrwxrwxrwx.  1 root    root       7 Aug  7 05:49 bin -> usr/bin
drwxr-xr-x.  2 root    root       6 May 12  2018 boot
drwxr-xr-x.  2 root    root       6 May 12  2018 dev
drwxr-xr-x. 79 root    root    8192 Aug  7 05:43 etc
drwxr-xr-x.  3 root    root      21 May 12  2018 home
lrwxrwxrwx.  1 root    root       7 Aug  7 05:49 lib -> usr/lib
lrwxrwxrwx.  1 root    root       9 Aug  7 05:49 lib64 -> usr/lib64
drwxr-xr-x.  2 root    root       6 Apr 11  2018 media
drwxr-xr-x.  2 root    root       6 Apr 11  2018 mnt
drwxr-xr-x.  2 root    root       6 Apr 11  2018 opt
drwxr-xr-x.  2 root    root       6 May 12  2018 proc
dr-xr-x---.  3 root    root     167 Aug  7 05:48 root
drwxr-xr-x.  2 root    root       6 May 12  2018 run
lrwxrwxrwx.  1 root    root       8 Aug  7 05:49 sbin -> usr/sbin
drwxr-xr-x.  2 root    root       6 Apr 11  2018 srv
drwxr-xr-x.  2 root    root       6 May 12  2018 sys
drwxrwxrwt.  8 root    root     256 Aug  7 05:44 tmp
drwxr-xr-x. 13 root    root     155 May 12  2018 usr
drwxr-xr-x.  2 vagrant vagrant   43 Aug  6 10:06 vagrant
drwxr-xr-x. 18 root    root     254 Aug  7 05:42 var
```

Переконфигурируем grub для того, чтобы при старте перейти в новый "/" раздел:
```bash
[root@lvm ~]#for i in /proc/ /sys/ /dev/ /run/ /boot/; do mount --bind $i /mnt/$i; done
[root@lvm ~]#chroot /mnt
[root@lvm /]# grub2-mkconfig -o /boot/grub2/grub.cfg
Generating grub configuration file ...
Found linux image: /boot/vmlinuz-3.10.0-862.2.3.el7.x86_64
Found initrd image: /boot/initramfs-3.10.0-862.2.3.el7.x86_64.img
done
```

Обновим образ initrd:
```bash
[root@lvm /]# cd /boot ; for i in `ls initramfs-*img`; do dracut -v $i `echo $i | sed "s/initramfs-//g; s/.img//g"` --force; done
**************************
*** No early-microcode cpio image needed ***
*** Store current command line parameters ***
*** Creating image file ***
*** Creating image file done ***
*** Creating initramfs image file '/boot/initramfs-3.10.0-862.2.3.el7.x86_64.img' done ***
```

Правим в файле /boot/grub2/grub.cfg значение rd.lvm.lv=VolGroup00/LogVol00 на rd.lvm.lv=vg_root/lv_root:
```bash
[root@lvm ~]# vi /boot/grub2/grub.cfg
```

Перезагружаемся и проверяем:
```bash
[root@lvm ~]# lsblk 
NAME                    MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
sda                       8:0    0   40G  0 disk 
├─sda1                    8:1    0    1M  0 part 
├─sda2                    8:2    0    1G  0 part /boot
└─sda3                    8:3    0   39G  0 part 
  ├─VolGroup00-LogVol01 253:1    0  1.5G  0 lvm  [SWAP]
  └─VolGroup00-LogVol00 253:2    0 37.5G  0 lvm  
sdb                       8:16   0   10G  0 disk 
└─vg_root-lv_root       253:0    0   10G  0 lvm  /
sdc                       8:32   0    2G  0 disk 
sdd                       8:48   0    1G  0 disk 
sde                       8:64   0    1G  0 disk 
```
Удаляем старый раздел LV:
```bash
[root@lvm ~]# lvremove /dev/VolGroup00/LogVol00
Do you really want to remove active logical volume VolGroup00/LogVol00? [y/n]: y
  Logical volume "LogVol00" successfully removed
```

Создаем новый раздел LV на 8G:
```bash
[root@lvm ~]# lvcreate -n VolGroup00/LogVol00 -L 8G /dev/VolGroup00
WARNING: xfs signature detected on /dev/VolGroup00/LogVol00 at offset 0. Wipe it? [y/n]: y
  Wiping xfs signature on /dev/VolGroup00/LogVol00.
  Logical volume "LogVol00" created.
```

Создем на новом томе файловую систему и монтируем его для переноса данных из действующего "/" раздела:
```bash
[root@lvm ~]# mkfs.xfs /dev/VolGroup00/LogVol00
meta-data=/dev/VolGroup00/LogVol00 isize=512    agcount=4, agsize=524288 blks
         =                       sectsz=512   attr=2, projid32bit=1
         =                       crc=1        finobt=0, sparse=0
data     =                       bsize=4096   blocks=2097152, imaxpct=25
         =                       sunit=0      swidth=0 blks
naming   =version 2              bsize=4096   ascii-ci=0 ftype=1
log      =internal log           bsize=4096   blocks=2560, version=2
         =                       sectsz=512   sunit=0 blks, lazy-count=1
realtime =none                   extsz=4096   blocks=0, rtextents=0
[root@lvm ~]# mount /dev/VolGroup00/LogVol00 /mnt
```

Копируем все данные с "/" раздела в примонтированный /mnt:
```bash
[root@lvm ~]# xfsdump -J - /dev/vg_root/lv_root | xfsrestore -J - /mnt
****************************
xfsdump: media file size 740144744 bytes
xfsdump: dump size (non-dir files) : 726982008 bytes
xfsdump: dump complete: 35 seconds elapsed
xfsdump: Dump Status: SUCCESS
xfsrestore: restore complete: 35 seconds elapsed
xfsrestore: Restore Status: SUCCESS
```

Переконфигурируем grub, за исключением правки /etc/grub2/grub.cfg:
```bash
[root@lvm ~]# for i in /proc/ /sys/ /dev/ /run/ /boot/; do mount --bind $i /mnt/$i; done
[root@lvm ~]# chroot /mnt
[root@lvm /]# grub2-mkconfig -o /boot/grub2/grub.cfg
Generating grub configuration file ...
Found linux image: /boot/vmlinuz-3.10.0-862.2.3.el7.x86_64
Found initrd image: /boot/initramfs-3.10.0-862.2.3.el7.x86_64.img
done
```

Обновим образ initrd:
```bash
[root@lvm /]# cd /boot ; for i in `ls initramfs-*img`; do dracut -v $i `echo $i|sed "s/initramfs-//g; s/.img//g"` --force; done
***********************
*** Generating early-microcode cpio image contents ***
*** No early-microcode cpio image needed ***
*** Store current command line parameters ***
*** Creating image file ***
*** Creating image file done ***
*** Creating initramfs image file '/boot/initramfs-3.10.0-862.2.3.el7.x86_64.img' done ***
```

Создаем зеркало под /var на ранее созданом PV /dev/sdс /dev/sde:
```bash
[root@lvm boot]# vgcreate vg_var /dev/sdc /dev/sde 
  Volume group "vg_var" successfully created
[root@lvm boot]# lvcreate -L 950M -m1 -n lv_var vg_var
  Rounding up size to full physical extent 952.00 MiB
  Logical volume "lv_var" created.
```

Создаем файловую систему,монтируем и перемещаем туда /var:

```bash
[root@lvm boot]# mkfs.ext4 /dev/vg_var/lv_var
mke2fs 1.42.9 (28-Dec-2013)
Filesystem label=
OS type: Linux
Block size=4096 (log=2)
Fragment size=4096 (log=2)
Stride=0 blocks, Stripe width=0 blocks
60928 inodes, 243712 blocks
12185 blocks (5.00%) reserved for the super user
First data block=0
Maximum filesystem blocks=249561088
8 block groups
32768 blocks per group, 32768 fragments per group
7616 inodes per group
Superblock backups stored on blocks: 
	32768, 98304, 163840, 229376

Allocating group tables: done                            
Writing inode tables: done                            
Creating journal (4096 blocks): done
Writing superblocks and filesystem accounting information: done

[root@lvm boot]# mount /dev/vg_var/lv_var /mnt
[root@lvm boot]# rsync -avHPSAX /var/ /mnt/
**************************
sent 138,945,216 bytes  received 253,067 bytes  25,308,778.73 bytes/sec
total size is 138,514,753  speedup is 1.00
```

Сохраняем или удаляем файлы из старого /var:
```bash
#mkdir /tmp/oldvar && mv /var/* /tmp/oldvar
#rm -rf /home/*
```

Отмонтируем новый раздел под /var и смонтируем его в директорию /var:
```bash
[root@lvm boot]# umount /mnt
[root@lvm boot]# mount /dev/vg_var/lv_var /var
```

Правим fstab для автоматического монтирования /var:
```bash
[root@lvm boot]# echo "`blkid | grep var: | awk '{print $2}'` /var ext4 defaults 0 0" >> /etc/fstab
```

Перезагружаемся:
```bash
[root@lvm ~]# reboot 
```

Проверяем:
```bash
[root@lvm ~]# lsblk
NAME                     MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
sda                        8:0    0   40G  0 disk 
├─sda1                     8:1    0    1M  0 part 
├─sda2                     8:2    0    1G  0 part /boot
└─sda3                     8:3    0   39G  0 part 
  ├─VolGroup00-LogVol00  253:0    0    8G  0 lvm  /
  └─VolGroup00-LogVol01  253:1    0  1.5G  0 lvm  [SWAP]
sdb                        8:16   0   10G  0 disk 
└─vg_root-lv_root        253:2    0   10G  0 lvm  
sdc                        8:32   0    2G  0 disk 
├─vg_var-lv_var_rmeta_0  253:3    0    4M  0 lvm  
│ └─vg_var-lv_var        253:7    0  952M  0 lvm  /var
└─vg_var-lv_var_rimage_0 253:4    0  952M  0 lvm  
  └─vg_var-lv_var        253:7    0  952M  0 lvm  /var
sdd                        8:48   0    1G  0 disk 
sde                        8:64   0    1G  0 disk 
├─vg_var-lv_var_rmeta_1  253:5    0    4M  0 lvm  
│ └─vg_var-lv_var        253:7    0  952M  0 lvm  /var
└─vg_var-lv_var_rimage_1 253:6    0  952M  0 lvm  
  └─vg_var-lv_var        253:7    0  952M  0 lvm  /var
```

Удаляем временный Volume Group, который использовался под временный /:
```bash
[root@lvm ~]# lvremove /dev/vg_root/lv_root
Do you really want to remove active logical volume vg_root/lv_root? [y/n]: y
  Logical volume "lv_root" successfully removed
[root@lvm ~]# vgremove /dev/vg_root
  Volume group "vg_root" successfully removed
[root@lvm ~]# pvremove /dev/sdb
  Labels on physical volume "/dev/sdb" successfully wiped.
```

Выделяем том под /home:
```bash
[root@lvm ~]# lvcreate -n LogVol_Home -L 2G /dev/VolGroup00
  Logical volume "LogVol_Home" created.

[root@lvm ~]# lvs
LV          VG         Attr       LSize   Pool Origin Data%  Meta%  Move Log Cpy%Sync Convert
LogVol00    VolGroup00 -wi-ao----   8.00g                                                    
LogVol01    VolGroup00 -wi-ao----   1.50g                                                    
LogVol_Home VolGroup00 -wi-a-----   2.00g                                                    
lv_var      vg_var     rwi-aor--- 952.00m                                    100.00  
```

Создаем файловую систему,монтируем и перемещаем туда /home:
```bash
[root@lvm ~]# mkfs.xfs /dev/VolGroup00/LogVol_Home
meta-data=/dev/VolGroup00/LogVol_Home isize=512    agcount=4, agsize=131072 blks
         =                       sectsz=512   attr=2, projid32bit=1
         =                       crc=1        finobt=0, sparse=0
data     =                       bsize=4096   blocks=524288, imaxpct=25
         =                       sunit=0      swidth=0 blks
naming   =version 2              bsize=4096   ascii-ci=0 ftype=1
log      =internal log           bsize=4096   blocks=2560, version=2
         =                       sectsz=512   sunit=0 blks, lazy-count=1
realtime =none                   extsz=4096   blocks=0, rtextents=0
[root@lvm ~]# mount /dev/VolGroup00/LogVol_Home /mnt
[root@lvm ~]# rsync -avHPSAX /home/* /mnt
**********************
sent 1,484 bytes  received 109 bytes  3,186.00 bytes/sec
total size is 831  speedup is 0.52
```

Сохраняем или удаляем файлы из старого /var:
```bash
#mkdir /tmp/oldhome && mv /home/* /tmp/oldhome
#rm -rf /home/*
```

Отмонтируем новый раздел под /home  и смонтируем его в директорию /home :
```bash
[root@lvm ~]# umount /mnt
[root@lvm ~]# mount /dev/VolGroup00/LogVol_Home /home/
```

Правим fstab для автоматического монтирования /home:
```bash
[root@lvm ~]# echo "`blkid | grep Home | awk '{print $2}'` /home xfs defaults 0 0" >> /etc/fstab
```

Сгенерируем несколько сотен файлов в /home/*:
```bash
[root@lvm ~]# touch /home/file{1..250}

[root@lvm ~]# ls /home/
/home/:
file1    file111  file124  file137  file15   file162  file175  file188  file20   file212  file225  file238  file250  file38  file50  file63  file76  file89
file10   file112  file125  file138  file150  file163  file176  file189  file200  file213  file226  file239  file26   file39  file51  file64  file77  file9
file100  file113  file126  file139  file151  file164  file177  file19   file201  file214  file227  file24   file27   file4   file52  file65  file78  file90
file101  file114  file127  file14   file152  file165  file178  file190  file202  file215  file228  file240  file28   file40  file53  file66  file79  file91
file102  file115  file128  file140  file153  file166  file179  file191  file203  file216  file229  file241  file29   file41  file54  file67  file8   file92
file103  file116  file129  file141  file154  file167  file18   file192  file204  file217  file23   file242  file3    file42  file55  file68  file80  file93
file104  file117  file13   file142  file155  file168  file180  file193  file205  file218  file230  file243  file30   file43  file56  file69  file81  file94
file105  file118  file130  file143  file156  file169  file181  file194  file206  file219  file231  file244  file31   file44  file57  file7   file82  file95
file106  file119  file131  file144  file157  file17   file182  file195  file207  file22   file232  file245  file32   file45  file58  file70  file83  file96
file107  file12   file132  file145  file158  file170  file183  file196  file208  file220  file233  file246  file33   file46  file59  file71  file84  file97
file108  file120  file133  file146  file159  file171  file184  file197  file209  file221  file234  file247  file34   file47  file6   file72  file85  file98
file109  file121  file134  file147  file16   file172  file185  file198  file21   file222  file235  file248  file35   file48  file60  file73  file86  file99
file11   file122  file135  file148  file160  file173  file186  file199  file210  file223  file236  file249  file36   file49  file61  file74  file87  vagrant
file110  file123  file136  file149  file161  file174  file187  file2    file211  file224  file237  file25   file37   file5   file62  file75  file88
```

Делаем снапшот:
```bash
[root@lvm ~]# lvcreate -L 100MB -s -n home_snap /dev/VolGroup00/LogVol_Home
  Rounding up size to full physical extent 128.00 MiB
  Logical volume "home_snap" created.
```

Удаляем часть файлов:
```bash
[root@lvm ~]# rm -f /home/file{100..150}

[root@lvm ~]# ls -l /home/
total 0
-rw-r--r--. 1 root    root     0 Aug  7 06:37 file1
-rw-r--r--. 1 root    root     0 Aug  7 06:37 file2
-rw-r--r--. 1 root    root     0 Aug  7 06:37 file3
-rw-r--r--. 1 root    root     0 Aug  7 06:37 file4
drwx------. 3 vagrant vagrant 74 May 12  2018 vagrant
```

Восстанавливаем из снапшота home_snap:
```bash
[root@lvm ~]# umount /home
[root@lvm ~]# lvconvert --merge /dev/VolGroup00/home_snap
  Merging of volume VolGroup00/home_snap started.
  VolGroup00/LogVol_Home: Merged: 99.95%
  VolGroup00/LogVol_Home: Merged: 100.00%
[root@lvm ~]# mount /home
[root@lvm ~]# ls /home/
file1    file111  file124  file137  file15   file162  file175  file188  file20   file212  file225  file238  file250  file38  file50  file63  file76  file89
file10   file112  file125  file138  file150  file163  file176  file189  file200  file213  file226  file239  file26   file39  file51  file64  file77  file9
file100  file113  file126  file139  file151  file164  file177  file19   file201  file214  file227  file24   file27   file4   file52  file65  file78  file90
file101  file114  file127  file14   file152  file165  file178  file190  file202  file215  file228  file240  file28   file40  file53  file66  file79  file91
file102  file115  file128  file140  file153  file166  file179  file191  file203  file216  file229  file241  file29   file41  file54  file67  file8   file92
file103  file116  file129  file141  file154  file167  file18   file192  file204  file217  file23   file242  file3    file42  file55  file68  file80  file93
file104  file117  file13   file142  file155  file168  file180  file193  file205  file218  file230  file243  file30   file43  file56  file69  file81  file94
file105  file118  file130  file143  file156  file169  file181  file194  file206  file219  file231  file244  file31   file44  file57  file7   file82  file95
file106  file119  file131  file144  file157  file17   file182  file195  file207  file22   file232  file245  file32   file45  file58  file70  file83  file96
file107  file12   file132  file145  file158  file170  file183  file196  file208  file220  file233  file246  file33   file46  file59  file71  file84  file97
file108  file120  file133  file146  file159  file171  file184  file197  file209  file221  file234  file247  file34   file47  file6   file72  file85  file98
file109  file121  file134  file147  file16   file172  file185  file198  file21   file222  file235  file248  file35   file48  file60  file73  file86  file99
file11   file122  file135  file148  file160  file173  file186  file199  file210  file223  file236  file249  file36   file49  file61  file74  file87  vagrant
file110  file123  file136  file149  file161  file174  file187  file2    file211  file224  file237  file25   file37   file5   file62  file75  file88
```


# *Работа с btrfs*


Создаем физические тома:
```bash
[root@lvm ~]# pvcreate /dev/sd{b,c}
  Physical volume "/dev/sdb" successfully created.
  Physical volume "/dev/sdc" successfully created.
```
На этих физических томах создаём группу vg
```bash
[root@lvm ~]# vgcreate vg /dev/sd{b,c}
  Volume group "vg" successfully created
```

Создаем lv для метаданных,данных и /opt:
```bash
[root@lvm ~]# lvcreate -n lv_opt -L 10G /dev/vg
  Logical volume "lv_opt" created.
[root@lvm ~]# lvcreate -n metacache_lv -L 20 vg 
  Logical volume "metacache_lv" created.
[root@lvm ~]# lvcreate -n datacache_lv -L 1G vg 
  Logical volume "datacache_lv" created.
```

```bash
[root@lvm ~]# lvs
  LV           VG         Attr       LSize   Pool Origin Data%  Meta%  Move Log Cpy%Sync Convert
  LogVol00     VolGroup00 -wi-ao---- <37.47g                                                    
  LogVol01     VolGroup00 -wi-ao----   1.50g                                                    
  datacache_lv vg         -wi-a-----   1.00g                                                    
  lv_opt       vg         -wi-a-----  10.00g                                                    
  metacache_lv vg         -wi-a-----  20.00m 
```
    
Создаем пул из томов данных и метаданных:
```bash
[root@lvm ~]# lvconvert --type cache-pool --cachemode writeback --poolmetadata vg/metacache_lv vg/datacache_lv
  WARNING: Converting vg/datacache_lv and vg/metacache_lv to cache pool's data and metadata volumes with metadata wiping.
  THIS WILL DESTROY CONTENT OF LOGICAL VOLUME (filesystem etc.)
Do you really want to convert vg/datacache_lv and vg/metacache_lv? [y/n]: y
  Converted vg/datacache_lv and vg/metacache_lv to cache pool.
```

Cборка кеша из исходного тома данных и пула:
```bash
[root@lvm ~]# lvconvert --type cache --cachepool vg/datacache_lv vg/lv_opt
Do you want wipe existing metadata of cache pool vg/datacache_lv? [y/n]: y
  Logical volume vg/lv_opt is now cached.
```

Создаем файловую btrfs и монтируем:
```bash
[root@lvm ~]# mkfs.btrfs /dev/vg/lv_opt 
btrfs-progs v4.9.1
See http://btrfs.wiki.kernel.org for more information.

Performing full device TRIM /dev/vg/lv_opt (10.00GiB) ...
Label:              (null)
UUID:               fb5a1423-3453-49de-a03c-9fb04403d9b5
Node size:          16384
Sector size:        4096
Filesystem size:    10.00GiB
Block group profiles:
  Data:             single            8.00MiB
  Metadata:         DUP               1.00GiB
  System:           DUP               8.00MiB
SSD detected:       no
Incompat features:  extref, skinny-metadata
Number of devices:  1
Devices:
   ID        SIZE  PATH
    1    10.00GiB  /dev/vg/lv_opt
[root@lvm ~]# mount /dev/vg/lv_opt /opt/
```

Посмотрим информацию о только что созданной файловой:
```bash
[root@lvm ~]# btrfs filesystem  /opt
Label: none  uuid: fb5a1423-3453-49de-a03c-9fb04403d9b5
	Total devices 1 FS bytes used 384.00KiB
	devid    1 size 10.00GiB used 2.02GiB path /dev/mapper/vg-lv_opt
```

Уменьшим размер тома на 500М в реальном времени:
```bash
[root@lvm ~]# btrfs filesystem resize -500M /opt
Resize '/opt' of '-500M'
[root@lvm ~]# btrfs filesystem show
Label: none  uuid: fb5a1423-3453-49de-a03c-9fb04403d9b5
	Total devices 1 FS bytes used 384.00KiB
	devid    1 size 9.51GiB used 2.02GiB path /dev/mapper/vg-lv_opt
```

Вернем предыдущий размер:
```bash
[root@lvm ~]# btrfs filesystem resize +500M /opt
Resize '/opt' of '+500M'
[root@lvm ~]# btrfs filesystem show
Label: none  uuid: fb5a1423-3453-49de-a03c-9fb04403d9b5
	Total devices 1 FS bytes used 384.00KiB
	devid    1 size 10.00GiB used 2.02GiB path /dev/mapper/vg-lv_opt
```

Создадим несколько подтомов:
```bash
[root@lvm ~]# btrfs subvolume create /opt/subvol1
Create subvolume '/opt/subvol1'
[root@lvm ~]# btrfs subvolume create /opt/subvol2
Create subvolume '/opt/subvol2'
```
Перейдем в один из подтомов и сгенерируем несколько файлов:
```bash
[root@lvm ~]# cd /opt/subvol1
[root@lvm subvol1]# touch file{1..10}
[root@lvm subvol1]# ls 
file1  file10  file2  file3  file4  file5  file6  file7  file8  file9
```

Создадим snapshot подтома subvol1 со сгенерированными данными:
```bash
[root@lvm subvol1]# btrfs subvolume snapshot /opt/subvol1/ /opt/subvol1_snapshot
Create a snapshot of '/opt/subvol1/' in '/opt/subvol1_snapshot'
[root@lvm subvol1]# rm -rf file{1..5}
[root@lvm subvol1]# ls 
file10  file6  file7  file8  file9
[root@lvm subvol1]# btrfs subvolume list /opt
ID 256 gen 15 top level 5 path subvol1
ID 257 gen 12 top level 5 path subvol2
ID 258 gen 14 top level 5 path subvol1_snapshot
```

Удалим созданный подтом и восстановим данные:
```bash
[root@lvm opt]# btrfs subvolume delete /opt/subvol1
Delete subvolume (no-commit): '/opt/subvol1'
[root@lvm opt]# btrfs subvolume snapshot /opt/subvol1_snapshot/ /opt/subvol1
Create a snapshot of '/opt/subvol1_snapshot/' in '/opt/subvol1'
[root@lvm subvol1]# ls
file1  file10  file2  file3  file4  file5  file6  file7  file8  file9
```

