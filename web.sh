# 关闭防火墙
systemctl stop firewalld
systemctl disable firewalld

# 关闭SELinux
sed -i 's/SELINUX=enforcing/SELINUX=disabled/' /etc/selinux/config
setenforce 0

# 安装 Nginx
yum install -y nginx
systemctl start nginx.service 
systemctl enable nginx.service 

# 安装 PHP 和 PHP-FPM
yum -y install php-fpm php*
systemctl start php-fpm
systemctl enable php-fpm

# 修改 PHP-FPM 配置文件中的用户和组
sed -i 's/user = apache/user = nginx/' /etc/php-fpm.d/www.conf
sed -i 's/group = apache/group = nginx/' /etc/php-fpm.d/www.conf

# 重启 PHP-FPM 和 Nginx 服务
systemctl restart php-fpm
systemctl restart nginx

# 克隆 Git 仓库并移动文件到 Nginx 默认网站目录
git clone https://ghp.ci/https://github.com/bl4e/web.git
cd web
mv upload/* /usr/share/nginx/html/

# 重启 Nginx 以应用更改
systemctl restart nginx
echo "Setup complete!"
