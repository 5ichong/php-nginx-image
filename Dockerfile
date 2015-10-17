FROM index.alauda.cn/tutum/centos:6.5

MAINTAINER Weijian Zhang <zhangwj@5ichong.com>

# yum安装依赖
RUN LANG=C
RUN yum -y install gcc gcc-c++ autoconf libjpeg libjpeg-devel libpng libpng-devel freetype freetype-devel libxml2 libxml2-devel zlib zlib-devel glibc glibc-devel glib2 glib2-devel bzip2 bzip2-devel ncurses ncurses-devel curl curl-devel e2fsprogs e2fsprogs-devel krb5 krb5-devel libidn libidn-devel openssl openssl-devel openldap openldap-devel nss_ldap openldap-clients openldap-servers wget curl vim cmake libaio tar perl-ExtUtils-CBuilder perl-ExtUtils-MakeMaker libxslt-devel unzip zip

# 创建基础目录
RUN mkdir -p /opt/case/ && mkdir -p /opt/app/ && mkdir -p /opt/src/ && mkdir -p /opt/logs/

# 下载所以依赖
WORKDIR /opt/src/
RUN wget http://tengine.taobao.org/download/tengine-2.1.0.tar.gz
RUN wget http://cn2.php.net/distributions/php-5.6.11.tar.gz
RUN wget http://nchc.dl.sourceforge.net/project/pcre/pcre/8.36/pcre-8.36.tar.gz
RUN wget http://luajit.org/download/LuaJIT-2.0.4.tar.gz
RUN wget http://labs.frickle.com/files/ngx_cache_purge-2.3.tar.gz
RUN wget http://down1.chinaunix.net/distfiles/libiconv-1.14.tar.gz
RUN wget http://www.mirrorservice.org/sites/dl.sourceforge.net/pub/sourceforge/a/au/autonpfmp/NPFMP/libmcrypt-2.5.8.tar.gz
RUN wget http://jaist.dl.sourceforge.net/project/lempelf/packages/mhash-0.9.9.9.tar.gz
RUN wget http://ncu.dl.sourceforge.net/project/lnmpaio/web/mcrypt/mcrypt-2.6.8.tar.gz
RUN wget http://blog.zyan.cc/soft/linux/nginx_php/imagick/ImageMagick.tar.gz
RUN wget https://github.com/nicolasff/phpredis/archive/master.zip
RUN wget http://pecl.php.net/get/imagick-3.1.2.tgz

# 编译环境
RUN wget https://www.percona.com/downloads/Percona-Server-5.6/Percona-Server-5.6.26-74.0/binary/redhat/6/x86_64/Percona-Server-client-56-5.6.26-rel74.0.el6.x86_64.rpm
RUN wget https://www.percona.com/downloads/Percona-Server-5.6/Percona-Server-5.6.26-74.0/binary/redhat/6/x86_64/Percona-Server-server-56-5.6.26-rel74.0.el6.x86_64.rpm
RUN wget https://www.percona.com/downloads/Percona-Server-5.6/Percona-Server-5.6.26-74.0/binary/redhat/6/x86_64/Percona-Server-shared-56-5.6.26-rel74.0.el6.x86_64.rpm
RUN rpm -ivh *.rpm
RUN service mysql start

RUN tar -zxvf tengine-2.1.0.tar.gz && tar -zxvf php-5.6.11.tar.gz && tar -zxvf pcre-8.36.tar.gz && tar -zxvf LuaJIT-2.0.4.tar.gz && tar -zxvf ngx_cache_purge-2.3.tar.gz
RUN tar -zxvf libiconv-1.14.tar.gz && tar -zxvf libmcrypt-2.5.8.tar.gz && tar -zxvf mhash-0.9.9.9.tar.gz && tar -zxvf mcrypt-2.6.8.tar.gz && tar -zxvf ImageMagick.tar.gz && tar -zxvf imagick-3.1.2.tgz

WORKDIR /opt/src/pcre-8.36
RUN ./configure
RUN make && make install

WORKDIR /opt/src/LuaJIT-2.0.4
RUN mkdir /usr/local/luaJIT
RUN make && make install PREFIX=/usr/local/luaJIT
RUN ln -sf LuaJIT-2.0.3 /usr/local/luaJIT/bin/luajit
RUN export LUAJIT_LIB=/usr/local/luaJIT/lib
RUN export LUAJIT_INC=/usr/local/luaJIT/include/luajit-2.0

WORKDIR /opt/src/tengine-2.1.0
RUN useradd -M -s /sbin/nologin www
RUN ./configure --prefix=/opt/app/nginx --user=www --group=www --with-http_stub_status_module --with-http_sub_module --with-http_ssl_module --with-http_flv_module --with-http_gzip_static_module --with-http_concat_module=shared --with-http_sysguard_module=shared --with-ipv6 --with-http_spdy_module --add-module=../ngx_cache_purge-2.3 --with-http_slice_module=shared --with-http_random_index_module=shared --with-http_secure_link_module=shared --with-http_sysguard_module=shared --with-http_mp4_module=shared --with-http_lua_module=shared --with-luajit-inc=/usr/local/luaJIT/include/luajit-2.0 --with-luajit-lib=/usr/local/luaJIT/lib --with-http_concat_module=shared --with-syslog --with-http_upstream_check_module
RUN make && make install

WORKDIR /opt/src/libiconv-1.14
RUN ./configure --prefix=/usr/local
RUN make && make install

WORKDIR /opt/src/libmcrypt-2.5.8
RUN ./configure
RUN make && make install
RUN /sbin/ldconfig
WORKDIR /opt/src/libmcrypt-2.5.8/libltdl/
RUN ./configure --enable-ltdl-install
RUN make && make install

WORKDIR /opt/src/mhash-0.9.9.9
RUN ./configure
RUN make && make install

WORKDIR /opt/src/ImageMagick-6.5.1-2
RUN ./configure
RUN make && make install

WORKDIR /opt/src/mcrypt-2.6.8
RUN echo '/usr/local/lib' > /etc/ld.so.conf.d/local.conf
RUN /sbin/ldconfig
RUN ln -s /usr/local/bin/libmcrypt-config /usr/bin/libmcrypt-config
RUN ln -s /lib64/libpcre.so.0.0.1 /lib64/libpcre.so.1
RUN ln -s /lib/libpcre.so.0.0.1 /lib/libpcre.so.1
ENV LD_LIBRARY_PATH /usr/local/lib
RUN /sbin/ldconfig
RUN ./configure
RUN make && make install

WORKDIR /opt/src/php-5.6.11
RUN cp -frp /usr/lib64/libldap* /usr/lib/
RUN ./configure --prefix=/opt/app/php5 --with-config-file-path=/opt/app/php5/etc --with-fpm-user=www --with-fpm-group=www --enable-fpm --with-mysql=mysqlnd --with-mysqli=mysqlnd --with-pdo-mysql=mysqlnd --disable-fileinfo --with-iconv-dir=/usr/local --with-freetype-dir --with-jpeg-dir --with-png-dir --with-zlib --with-libxml-dir=/usr --enable-xml --disable-rpath --enable-bcmath --enable-shmop --enable-exif --enable-sysvsem --enable-inline-optimization --with-curl --with-kerberos --enable-mbregex --enable-mbstring --with-mcrypt --with-gd --enable-gd-native-ttf --with-xsl --with-openssl --with-mhash --enable-pcntl --enable-sockets --with-ldap --with-ldap-sasl --with-xmlrpc --enable-ftp --with-gettext --enable-zip --enable-soap --disable-ipv6 --disable-debug --enable-opcache
RUN make ZEND_EXTRA_LIBS='-liconv'
RUN make install

# 编译第三方扩展
WORKDIR /opt/src/imagick-3.1.2
RUN export PKG_CONFIG_PATH=/usr/local/lib/pkgconfig
RUN /opt/app/php5/bin/phpize
RUN ./configure --with-php-config=/opt/app/php5/bin/php-config
RUN make && make install

WORKDIR /opt/src
RUN unzip master.zip
WORKDIR /opt/src/phpredis-master
RUN /opt/app/php5/bin/phpize
RUN ./configure --with-php-config=/opt/app/php5/bin/php-config
RUN make && make install

EXPOSE 80

EXPOSE 22

ENTRYPOINT /opt/app/php5/sbin/php-fpm && /opt/app/nginx/sbin/nginx && tail -f /opt/logs/nginx_error.log
