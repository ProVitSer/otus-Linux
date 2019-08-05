#!/bin/bash
# Сборка raid 5
mdadm --zero-superblock --force /dev/sd[bcde]
mdadm --create --verbose /dev/md0 --level=5 --raid-devices=4 /dev/sd[bcde]

#Создание файла mdadm.conf. В файле mdadm.conf находится информация о RAID-массивах и компонентах, которые в них входят
mkdir /etc/mdadm
echo "DEVICE partitions" > /etc/mdadm/mdadm.conf
mdadm --detail --scan --verbose | awk '/ARRAY/ {print}' >> /etc/mdadm/mdadm.conf

# GPT
parted -s /dev/md0  mklabel gpt

#Создание партиций
parted -s /dev/md0  mkpart 1 ext4 0% 20%
parted -s /dev/md0  mkpart 2 ext4 20% 40%
parted -s /dev/md0  mkpart 3 ext4 40% 60%
parted -s /dev/md0  mkpart 4 ext4 60% 80%
parted -s /dev/md0  mkpart 5 ext4 80% 100%

echo "# device      mountpoint     filesystemtype      options       dumpm     fsckorder" > /etc/fstab

#Создание файловой системы и монтирование массива
for i in 1 2 3 4 5
do
    mkfs.ext4 /dev/md0p$i
    mkdir -p /raid5/part$i
    mount /dev/md0p$i /raid5/part$i
    echo "  /dev/md0p$i      /raid5/part$i     ext4         default         0       0" >> /etc/fstab
done