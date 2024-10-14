#!/bin/bash

# 函数：检查命令执行状态
check_status() {
  if [ $? -ne 0 ]; then
    echo "Error executing: $1"
    exit 1
  fi
}

# 关闭防火墙
systemctl stop firewalld
check_status "Stopping firewalld"

systemctl disable firewalld
check_status "Disabling firewalld"

# 关闭 SELinux
sed -i 's/SELINUX=enforcing/SELINUX=disabled/' /etc/selinux/config
check_status "Disabling SELinux in config"

setenforce 0
check_status "Setting SELinux to permissive"

# 安装 Nginx
yum install -y nginx
check_status "Installing Nginx"

systemctl start nginx.service
check_status "Starting Nginx"

systemctl enable nginx.service
check_status "Enabling Nginx on boot"

# 安装 PHP 和 PHP-FPM
yum -y install php-fpm php*
check_status "Installing PHP and PHP-FPM"

systemctl start php-fpm
check_status "Starting PHP-FPM"

systemctl enable php-fpm
check_status "Enabling PHP-FPM on boot"

# 修改 PHP-FPM 配置文件中的用户和组
sed -i 's/user = apache/user = nginx/' /etc/php-fpm.d/www.conf
sed -i 's/group = apache/group = nginx/' /etc/php-fpm.d/www.conf
check_status "Updating PHP-FPM config to use nginx user/group"

# 重启 PHP-FPM 和 Nginx 服务
systemctl restart php-fpm
check_status "Restarting PHP-FPM"

systemctl restart nginx
check_status "Restarting Nginx"

# 克隆 Git 仓库并移动文件到 Nginx 默认网站目录
git clone https://ghp.ci/https://github.com/bl4e/web.git
check_status "Cloning Git repository"

cd web
mv upload/* /usr/share/nginx/html/
check_status "Moving web files to Nginx directory"

# 重启 Nginx 以应用更改
systemctl restart nginx
check_status "Final Nginx restart"

echo "Setup complete!"
