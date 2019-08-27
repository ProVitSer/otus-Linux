# **Управление пакетами. Дистрибьюция софта**
Размещаем свой RPM в своем репозитории
Цель: Часто в задачи администратора входит не только установка пакетов, но и сборка и поддержка собственного репозитория. Этим и займемся в ДЗ.
1) создать свой RPM (можно взять свое приложение, либо собрать к примеру апач с определенными опциями)
2) создать свой репо и разместить там свой RPM
реализовать это все либо в вагранте, либо развернуть у себя через nginx и дать ссылку на репо 

* реализовать дополнительно пакет через docker

------------

# **Vagrant**

Установить EPEL репозиторий
```bash
rpm -ivh https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
```

Установим необходимые пакеты для сборки
```bash
yum -y install createrepo httpd rpm-build rpmdevtools yum-utils autoconf automake gcc gcc-c++ less libpcap libpcap-devel libtool lksctp-tools lksctp-tools-devel ncurses ncurses-devel openssl openssl-devel gsl gsl-devel autoconf-archive gmock-devel gtest-devel gmock gtest nginx
```
Переходим в рабочую директорию, загружаем пакет с исходниками
```bash
cd /root/
yumdownloader --enablerepo=epel --source sipp
```

Добавляем пользователя mockbuild требуемый для установки и устанавливаем
```bash
useradd mockbuild
rpm -i sipp-3.5.1-1.el7.src.rpm
```

Устанавливаем оставшиеся зависимости, необходимые для сборки и запускаем сборку
```bash
yum-builddep rpmbuild/SPECS/sipp.spec -y
rpmbuild -bb rpmbuild/SPECS/sipp.spec
```

Создаем директорию под repo, переносим собранный rmp и запускам генерацию метаданных репозитория
```bash
mkdir /usr/share/nginx/html/repo
cp /root/rpmbuild/RPMS/x86_64/sipp-3.5.1-1.el7.centos.x86_64.rpm /usr/share/nginx/html/repo/
createrepo /usr/share/nginx/html/repo/
```

Включаем autoindex в nginx.conf 
```bash
sed -i "48i\\        autoindex on;"  /etc/nginx/nginx.conf
```

Добавим наш репозиторий
```bash
echo "[local-repo]" >> /etc/yum.repos.d/local.repo
echo "name=otus-local-repo" >> /etc/yum.repos.d/local.repo
echo "baseurl=http://localhost/repo" >> /etc/yum.repos.d/local.repo
echo "gpgcheck=0" >> /etc/yum.repos.d/local.repo
echo "enabled=1" >> /etc/yum.repos.d/local.repo
```

Запускаем nginx
```bash
systemctl start nginx
systemctl enable nginx
```

Устанавливаем sipp из локального репозитория
```bash
yum --disablerepo=* --enablerepo=local-repo install sipp
```

Проверяем работу
```bash
[root@repo ~]# sipp -v

 SIPp v3.5.1-TLS-SCTP-PCAP-RTPSTREAM built Aug 27 2019, 18:53:42.

 This program is free software; you can redistribute it and/or
 modify it under the terms of the GNU General Public License as
 published by the Free Software Foundation; either version 2 of
 the License, or (at your option) any later version.

 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.

 You should have received a copy of the GNU General Public
 License along with this program; if not, write to the
 Free Software Foundation, Inc.,
 59 Temple Place, Suite 330, Boston, MA  02111-1307 USA

 Author: see source files.
```

Запуск стенда
```bash
vagrant up
```
Доступ к repo
```bash
curl http://127.0.0.1/repo/
http://192.168.15.137/repo/
```

# **Docker**

Сборка 
```bash
docker build -t provitser/otus .
```
Запуск контейнера
```bash
docker run -d -p 88888:80 provitser/otus 
```

Доступ к репозитарию
```bash
http://127.0.0.1:8888/repo/
```