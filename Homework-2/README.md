# **Работа с mdadm**

В этом задании необходимо продемонстрировать умение работать с software raid и инструментами для работы с работы с разделами(parted,fdisk,lsblk)
добавить в Vagrantfile еще дисков
сломать/починить raid
собрать R0/R5/R10 - на выбор 
создать на рейде GPT раздел и 5 партиций

в качестве проверки принимаются - измененный Vagrantfile, скрипт для создания рейда

* доп. задание - Vagrantfile, который сразу собирает систему с подключенным рейдом

Запустим виртуалку  с помощью 
```bash
vagrant up
```

Vagrantfle содержит область подключения скрипта сборки raid5
```bash
box.vm.provision "shell", path: "./script/script.sh"
```

Подробную информацию о конкретном массиве можно посмотреть командой:
```bash
mdadm --detail /dev/md0
```
```bash
/dev/md0:
           Version : 1.2
     Creation Time : Mon Aug  5 14:57:53 2019
        Raid Level : raid5
        Array Size : 761856 (744.00 MiB 780.14 MB)
     Used Dev Size : 253952 (248.00 MiB 260.05 MB)
      Raid Devices : 4
     Total Devices : 4
       Persistence : Superblock is persistent

       Update Time : Mon Aug  5 14:58:29 2019
             State : clean 
    Active Devices : 4
   Working Devices : 4
    Failed Devices : 0
     Spare Devices : 0

            Layout : left-symmetric
        Chunk Size : 512K

Consistency Policy : resync

              Name : otuslinuxRAID:0  (local to host otuslinuxRAID)
              UUID : 830933c4:e923e8a2:26a3d07b:807c2e1d
            Events : 27

    Number   Major   Minor   RaidDevice State
       0       8       16        0      active sync   /dev/sdb
       1       8       32        1      active sync   /dev/sdc
       2       8       48        2      active sync   /dev/sdd
       4       8       64        3      active sync   /dev/sde
```

Ломаем один из дисков 
```bash
mdadm --manage /dev/md0 --fail /dev/sdd 
```

```bash
mdadm: set /dev/sdd faulty in /dev/md0
```

Удаляем его
```bash
mdadm --manage /dev/md0 --remove /dev/sdd
```

```bash
mdadm: hot removed /dev/sdd from /dev/md0
```

Проверяем
```bash
mdadm --detail /dev/md0
```

```bash
/dev/md0:
           Version : 1.2
     Creation Time : Mon Aug  5 14:57:53 2019
        Raid Level : raid5
        Array Size : 761856 (744.00 MiB 780.14 MB)
     Used Dev Size : 253952 (248.00 MiB 260.05 MB)
      Raid Devices : 4
     Total Devices : 3
       Persistence : Superblock is persistent

       Update Time : Mon Aug  5 15:15:49 2019
             State : clean, degraded 
    Active Devices : 3
   Working Devices : 3
    Failed Devices : 0
     Spare Devices : 0

            Layout : left-symmetric
        Chunk Size : 512K

Consistency Policy : resync

              Name : otuslinuxRAID:0  (local to host otuslinuxRAID)
              UUID : 830933c4:e923e8a2:26a3d07b:807c2e1d
            Events : 52

    Number   Major   Minor   RaidDevice State
       5       8       16        0      active sync   /dev/sdb
       1       8       32        1      active sync   /dev/sdc
       -       0        0        2      removed
       4       8       64        3      active sync   /dev/sde
```

Добавляем новый диск в raid
```bash
mdadm /dev/md0 --add /dev/sdd
```

```bash
/dev/md0:
           Version : 1.2
     Creation Time : Mon Aug  5 14:57:53 2019
        Raid Level : raid5
        Array Size : 761856 (744.00 MiB 780.14 MB)
     Used Dev Size : 253952 (248.00 MiB 260.05 MB)
      Raid Devices : 4
     Total Devices : 4
       Persistence : Superblock is persistent

       Update Time : Mon Aug  5 15:17:07 2019
             State : clean 
    Active Devices : 4
   Working Devices : 4
    Failed Devices : 0
     Spare Devices : 0

            Layout : left-symmetric
        Chunk Size : 512K

Consistency Policy : resync

              Name : otuslinuxRAID:0  (local to host otuslinuxRAID)
              UUID : 830933c4:e923e8a2:26a3d07b:807c2e1d
            Events : 71

    Number   Major   Minor   RaidDevice State
       5       8       16        0      active sync   /dev/sdb
       1       8       32        1      active sync   /dev/sdc
       6       8       48        2      active sync   /dev/sdd
       4       8       64        3      active sync   /dev/sde
```
