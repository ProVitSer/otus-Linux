FROM centos:7

ENV \
        HOME='/root'

RUN     yum -y install epel-release

RUN     yum -y install \
            createrepo \
            httpd \
            rpm-build \
            rpmdevtools \
            yum-utils \
            autoconf \
            automake \
            gcc \
            gcc-c++ \
            less \
            libpcap \
            libpcap-devel \
            libtool \
            lksctp-tools \
            lksctp-tools-devel \
            ncurses \
            ncurses-devel \
            openssl \
            openssl-devel \
            gsl \
            gsl-devel \
            autoconf-archive \
            gmock-devel \
            gtest-devel \
            gmock \
            gtest \
            nginx

RUN     cd $HOME/ &&\
        yumdownloader --enablerepo=epel --source sipp &&\
        useradd mockbuild &&\
        rpm -i sipp-3.5.1-1.el7.src.rpm

RUN     yum-builddep $HOME/rpmbuild/SPECS/sipp.spec -y &&\
        rpmbuild -bb $HOME/rpmbuild/SPECS/sipp.spec &&\
        mkdir /usr/share/nginx/html/repo

RUN     cp $HOME/rpmbuild/RPMS/x86_64/sipp-3.5.1-1.el7.x86_64.rpm /usr/share/nginx/html/repo/ &&\
        createrepo /usr/share/nginx/html/repo/ &&\
        sed -i "48i\\        autoindex on;"  /etc/nginx/nginx.conf &&\
        echo "[local-repo]" >> /etc/yum.repos.d/local.repo &&\
        echo "name=otus-local-repo" >> /etc/yum.repos.d/local.repo &&\
        echo "baseurl=http://localhost/repo" >> /etc/yum.repos.d/local.repo &&\
        echo "gpgcheck=0" >> /etc/yum.repos.d/local.repo &&\
        echo "enabled=1" >> /etc/yum.repos.d/local.repo

CMD ["nginx", "-g", "daemon off;"]