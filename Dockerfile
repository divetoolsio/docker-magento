FROM fgx-base
MAINTAINER fgx

ENV PHP_MEMORY_LIMIT    512M
ENV MAX_UPLOAD          50M
ENV PHP_MAX_FILE_UPLOAD 200
ENV PHP_MAX_POST        100M
ENV MAGENTO_VERSION	1.9.3.2

# install mysql, apache and php and php extensions, tzdata, wget
RUN apk update && \
    apk add \
    mysql mysql-client \
    apache2 \
    curl \
    wget \
    php5 \
    php5-cli \
    php5-xml \
    php5-pdo_mysql \
    php5-iconv \
    php5-dom \
    php5-json \
    php5-apache2 \
    php5-mysqli \
    php5-mysql \
    php5-curl \
    php5-gd \
    php5-mcrypt \
    php5-soap

#mysql settings
RUN mkdir -p /run/mysqld && \
    chown -R mysql:mysql /run/mysqld /var/lib/mysql && \
    mysql_install_db --user=root --basedir=/usr --datadir=/var/lib/mysql > /dev/null

RUN sed -i '/skip-external-locking/a log_error = \/var\/lib\/mysql\/error.log' /etc/mysql/my.cnf && \
    sed -i '/skip-external-locking/a general_log = ON' /etc/mysql/my.cnf && \
    sed -i '/skip-external-locking/a general_log_file = \/var\/lib\/mysql\/query.log' /etc/mysql/my.cnf

RUN ln -s /usr/lib/libxml2.so.2 /usr/lib/libxml2.so

#apache settings
RUN sed -i 's#AllowOverride None#AllowOverride All#' /etc/apache2/httpd.conf && \
    sed -i 's#ServerName www.example.com:80#\nServerName localhost:80#' /etc/apache2/httpd.conf && \
    sed -i 's#^DocumentRoot ".*#DocumentRoot "/www"#g' /etc/apache2/httpd.conf && \
    sed -i 's#/var/www/localhost/htdocs#/www#g' /etc/apache2/httpd.conf && \
    sed -i 's#\#LoadModule rewrite#LoadModule rewrite#' /etc/apache2/httpd.conf && \
    mkdir -p /run/apache2 && \
    chown -R apache:apache /run/apache2 && \
    mkdir /www && \
    echo "<?php phpinfo(); ?>" > /www/phpinfo.php && \
    chown -R apache:apache /www

#php settings
RUN sed -i "s|;*date.timezone =.*|date.timezone = ${TIMEZONE}|i" /etc/php5/php.ini && \
    sed -i "s|;*memory_limit =.*|memory_limit = ${PHP_MEMORY_LIMIT}|i" /etc/php5/php.ini && \
    sed -i "s|;*upload_max_filesize =.*|upload_max_filesize = ${MAX_UPLOAD}|i" /etc/php5/php.ini && \
    sed -i "s|;*max_file_uploads =.*|max_file_uploads = ${PHP_MAX_FILE_UPLOAD}|i" /etc/php5/php.ini && \
    sed -i "s|;*post_max_size =.*|post_max_size = ${PHP_MAX_POST}|i" /etc/php5/php.ini && \
    sed -i "s|;*cgi.fix_pathinfo=.*|cgi.fix_pathinfo= 0|i" /etc/php5/php.ini && \
    sed -i "s|;*display_errors =.*|display_errors = On|i" /etc/php5/php.ini

#prepare apache mysql startup script
RUN echo "#!/bin/bash" > /start.sh && echo "httpd" >> /start.sh && \
    echo "nohup mysqld --bind-address 0.0.0.0 --user root > /dev/null 2>&1 &" >> /start.sh && \
    echo "sleep 3" >> /start.sh && \
    echo "mysql -uroot -e 'create database magento;'" >> /start.sh && \
    echo "tail -f /var/log/apache2/access.log" >> /start.sh && \
    chmod u+x /start.sh && \
    chmod -R 777 /www

#get magento files
RUN mkdir /res
COPY magento-$MAGENTO_VERSION.tar.gz /res/magento-$MAGENTO_VERSION.tar.gz
RUN cd /res && tar xvf magento-$MAGENTO_VERSION.tar.gz && mv /res/magento-mirror-$MAGENTO_VERSION/* /res/magento-mirror-$MAGENTO_VERSION/.htaccess /www

#get magento sample data
COPY magento-sample-data-1.9.2.4.tar.gz /res/magento-sample-data-1.9.2.4.tar.gz

#add install script
ADD magento_install.sh /magento_install.sh
RUN chmod +x /magento_install.sh

RUN chmod -R 777 /www

WORKDIR /www

EXPOSE 80
EXPOSE 3306

VOLUME ["/www","/var/lib/mysql","/etc/mysql/"]
ENTRYPOINT /start.sh
