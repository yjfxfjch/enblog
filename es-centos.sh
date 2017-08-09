#!/bin/bash

updateSystem(){
    echo 'Start to update system softwares...'

    sudo yum install -y wget
    sudo yum install -y vim
    sudo yum install -y glibc.i686
    sudo wget http://www.atomicorp.com/installers/atomic
    sudo sh ./atomic -y
    sudo yum -y check-update
    sudo yum -y update

    echo 'Done.'
}

installNginx(){
    echo 'Start to install Nginx...'

    sudo yum install -y nginx
    sudo service nginx start 
    sudo chkconfig nginx on
    sudo sed -i '/sendfile        on;/ i client_max_body_size 1024M;' /etc/nginx/nginx.conf
    sudo rm /etc/nginx/conf.d/default.conf
    sudo rm /etc/nginx/conf.d/ssl.conf
    sudo rm /etc/nginx/conf.d/virtual.conf

    sudo echo 'server {

            listen 80;

            server_name test.yangjianfeng.com;

            root /usr/share/nginx/edusoho/web;

            access_log /var/log/nginx/edusoho.access.log;

            error_log /var/log/nginx/edusoho.error.log;

            location / { 

                index app.php;

                try_files $uri @rewriteapp;

            }

            location @rewriteapp {

                rewrite ^(.*)$ /app.php/$1 last;

            }

            location ~ ^/udisk {

                internal;

                root /usr/share/nginx/edusoho/app/data/;

            }

            location ~ ^/(app|app_dev)\.php(/|$) {

                fastcgi_pass   127.0.0.1:9000;

                fastcgi_split_path_info ^(.+\.php)(/.*)$;

                include fastcgi_params;

                fastcgi_param  SCRIPT_FILENAME    $document_root$fastcgi_script_name;

                fastcgi_param  HTTPS              off;

                fastcgi_param HTTP_X-Sendfile-Type X-Accel-Redirect;

                fastcgi_param HTTP_X-Accel-Mapping /udisk=/usr/share/nginx/edusoho/app/data/udisk;

                fastcgi_buffer_size 128k;

                fastcgi_buffers 8 128k;

            }

            location ~* \.(jpg|jpeg|gif|png|ico|swf)$ {

                expires 3y;

                access_log off;

                gzip off;

            }

            location ~* \.(css|js)$ {

                access_log off;

                expires 3y;

            }

            location ~ ^/files/.*\.(php|php5)$ {

                deny all;

            }

            location ~ \.php$ {

                fastcgi_pass   127.0.0.1:9000;

                fastcgi_split_path_info ^(.+\.php)(/.*)$;

                fastcgi_param  SCRIPT_FILENAME    $document_root$fastcgi_script_name;

                fastcgi_param  HTTPS              off;

                include        fastcgi_params;

            }

}' |sudo tee /etc/nginx/conf.d/edusoho.conf

    echo 'Done.'
}

installMysql(){
    echo 'Start to install MySql...'

    sudo yum install -y mysql mysql-server
    sudo chkconfig mysqld on
    sudo cp /usr/share/mysql/my-medium.cnf /etc/my.cnf
    sudo service mysqld restart
    sudo /usr/bin/mysqladmin -u root password 'root'
    mysql -uroot -proot -e"CREATE DATABASE edusoho DEFAULT CHARACTER SET utf8;"
    mysql -uroot -proot -e"GRANT ALL PRIVILEGES ON edusoho.* TO 'esuser'@'localhost' IDENTIFIED BY 'edusoho';"

    echo 'Done.'
}

installPhp(){
    echo 'Start to install PHP...'

    rpm -Uvh http://mirror.webtatic.com/yum/el6/latest.rpm
    yum install -y php55w php55w-cli php55w-curl php55w-fpm php55w-intl php55w-mcrypt php55w-mysql php55w-gd php55w-mbstring php55w-xml php55w-dom
    sudo sed -i 's/memory_limit.*/memory_limit = 1024M/g' /etc/php.ini
    sudo sed -i 's/upload_max_filesize.*/upload_max_filesize = 1024M/g' /etc/php.ini
    sudo sed -i 's/post_max_size.*/post_max_size = 1024M/g' /etc/php.ini
    sudo sed -i 's/max_execution_time.*/max_execution_time = 30000/g' /etc/php.ini
    sudo sed -i 's/max_input_time.*/max_input_time = 30000/g' /etc/php.ini

    # update php.ini to clean up login table on 1/1000 chance.
    sudo sed -i 's/session.gc_probability = 0/session.gc_probability = 1/g' /etc/php.ini
    chkconfig php-fpm on
    sudo service php-fpm restart

    echo 'Done.'
}

installEdusoho(){
    echo 'Start to install EduSoho...'

    #sudo  wget http://download.edusoho.com/edusoho-7.3.9.tar.gz
    sudo  git clone https://github.com/edusoho/edusoho.git
    sudo  cp -r edusoho /usr/share/nginx
    #sudo tar -zxvf edusoho-7.3.9.tar.gz -C /usr/share/nginx
    sudo chown apache:apache /usr/share/nginx/edusoho/ -Rf

    echo 'Done.'
}

updateIptables(){
    echo 'Start to update iptables...'

    iptables -A INPUT -j ACCEPT
    iptables -A INPUT -m state --state NEW -m tcp -p tcp --dport 80 -j ACCEPT
    service iptables save
    service iptables restart

    echo 'Done.'
}

turnOffSelinux(){
    echo 'Start to turn off Selinux...'

    sudo sed -i 's/SELINUX=.*/SELINUX=disabled/g' /etc/selinux/config

    echo 'Done.'
}

cleanup(){
    # echo 'Start to clean up and reboot system...'
    
    # sudo /etc/init.d/php-fpm restart
    # sudo /etc/init.d/nginx restart
    # sudo /etc/init.d/mysqld restart
    # /etc/init.d/iptables stop
    # sudo reboot
    echo 'Installation successful! Please reboot the system.'
}

echo '--------------------------------------------------------'
echo '----  Welcome to Use EduSoho Installation Script!  -----'
echo '--------------------------------------------------------'
echo 'This script will finish following tasks:'
echo '1. Update your Linux system softwares'
echo '2. Install Nginx Web server'
echo '3. Install MySql database server'
echo '4. Install PHP environment'
echo '5. Install EduSoho system'
echo '6. Clean up and get ready to reboot system'
echo '--------------------------------------------------------'

updateSystem
installNginx
installMysql
installPhp
installEdusoho
updateIptables
turnOffSelinux
cleanup

