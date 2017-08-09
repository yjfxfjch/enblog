#!/bin/bash

updateSystem(){
    echo '开始更新您的Linux系统软件...'

    sudo apt-get update -y
    sudo apt-get upgrade -y
    sudo apt-get install -y python-software-properties jq vim curl
}

installEdusoho(){
    echo '开始安装EduSoho...'

    #sudo wget http://download.edusoho.com/edusoho-7.3.9.tar.gz
    sudo  git clone https://github.com/edusoho/edusoho.git

    if [ ! -d "/var/www" ]; then
      sudo mkdir /var/www
    fi

    #sudo tar -zxvf edusoho-7.3.9.tar.gz -C /var/www
    sudo  cp -r edusoho /var/www
    sudo chown www-data:www-data /var/www/edusoho/ -Rf
    
}

installNginx(){
    echo '开始安装Nginx...'

    sudo add-apt-repository ppa:nginx/stable -y
    sudo apt-get install -y nginx
   	sudo sed -i '/sendfile on;/ i client_max_body_size 1024M;' /etc/nginx/nginx.conf
    sudo rm /etc/nginx/sites-enabled/default

	sudo echo 'server {
    listen 80;

    server_name localhost;

    root /var/www/edusoho/web;

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
        root /var/www/edusoho/app/data/;
    }

    location ~ ^/(app|app_dev)\.php(/|$) {
        fastcgi_pass   unix:/var/run/php5-fpm.sock;
        fastcgi_split_path_info ^(.+\.php)(/.*)$;
        include fastcgi_params;
        fastcgi_param  SCRIPT_FILENAME    $document_root$fastcgi_script_name;
        fastcgi_param  HTTPS              off;
        fastcgi_param HTTP_X-Sendfile-Type X-Accel-Redirect;
        fastcgi_param HTTP_X-Accel-Mapping /udisk=/var/www/edusoho/app/data/udisk;
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
        
        fastcgi_pass   unix:/var/run/php5-fpm.sock;
        fastcgi_split_path_info ^(.+\.php)(/.*)$;
        include fastcgi_params;
        fastcgi_param  SCRIPT_FILENAME    $document_root$fastcgi_script_name;
        fastcgi_param  HTTPS              off;
    }
}' |sudo tee /etc/nginx/sites-enabled/edusoho

}

installMysql(){
    echo '开始安装MySql...'

    echo 'mysql-server-5.5 mysql-server/root_password password root' | sudo debconf-set-selections
    echo 'mysql-server-5.5 mysql-server/root_password_again password root' | sudo debconf-set-selections
    sudo apt-get install -y mysql-server
    mysql -uroot -proot -e"CREATE DATABASE edusoho DEFAULT CHARACTER SET utf8;"
    mysql -uroot -proot -e"GRANT ALL PRIVILEGES ON edusoho.* TO 'esuser'@'localhost' IDENTIFIED BY 'edusoho';"
}

installPhp(){
    echo '开始安装PHP...'

    sudo apt-get install -y php5 php5-cli php5-curl php5-fpm php5-intl php5-mcrypt php5-mysqlnd php5-gd
    sudo sed -i 's/listen = 127.0.0.1:9000.*/listen = \/var\/run\/php5-fpm.sock/g' /etc/php5/fpm/pool.d/www.conf
    sudo sed -i 's/;listen.owner = www-data/listen.owner = www-data/g' /etc/php5/fpm/pool.d/www.conf
    sudo sed -i 's/;listen.group = www-data/listen.group = www-data/g' /etc/php5/fpm/pool.d/www.conf
    sudo sed -i 's/;listen.mode = 0660/listen.mode = 0660/g' /etc/php5/fpm/pool.d/www.conf
    sudo sed -i 's/memory_limit.*/memory_limit = 1024M/g' /etc/php5/fpm/php.ini
    sudo sed -i 's/upload_max_filesize.*/upload_max_filesize = 1024M/g' /etc/php5/fpm/php.ini
    sudo sed -i 's/post_max_size.*/post_max_size = 1024M/g' /etc/php5/fpm/php.ini
    sudo sed -i 's/max_execution_time.*/max_execution_time = 30000/g' /etc/php5/fpm/php.ini
    sudo sed -i 's/max_input_time.*/max_input_time = 30000/g' /etc/php5/fpm/php.ini

    # update php.ini to clean up login table on 1/1000 chance.
    sudo sed -i 's/session.gc_probability = 0/session.gc_probability = 1/g' /etc/php5/fpm/php.ini
}


updateIptables()
{
    sudo iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT&&sudo iptables -A INPUT -i lo -j ACCEPT&&sudo iptables -A INPUT -p TCP --dport 22 -j ACCEPT&&sudo iptables -A INPUT -p TCP --dport 80 -j ACCEPT&&sudo iptables -A INPUT -p TCP --dport 443 -j ACCEPT&&sudo iptables -A INPUT -p icmp -j ACCEPT&&sudo iptables -P INPUT DROP&&sudo iptables-save > /etc/iptables-rules&&sudo ip6tables-save > /etc/ip6tables-rules
    sudo echo 'pre-up iptables-restore < /etc/iptables-rules'>>/etc/network/interfaces
    sudo echo 'pre-up ip6tables-restore < /etc/ip6tables-rules'>>/etc/network/interfaces
}

cleanup(){
    echo '开始清理安装包并重启系统...'
    
    sudo apt-get autoremove
    sudo apt-get autoclean

    echo '安装完成，请重启系统。'
    # sudo reboot
}

echo '--------------------------------------------------------'
echo '----  欢迎使用EduSoho一键安装脚本！该脚本将自动完成以下任务： -----'
echo '--------------------------------------------------------'
echo '1. 更新您的Linux系统软件'
echo '2. 安装Nginx Web服务器'
echo '3. 安装MySql数据库服务器'
echo '4. 安装Php环境'
echo '5. 下载安装EduSoho系统'
echo '6. 清理安装包并准备重启系统'
echo '--------------------------------------------------------'

updateSystem
installNginx
installMysql
installPhp
installEdusoho
updateIptables
cleanup
