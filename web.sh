# 关闭防火墙
echo "Stopping and disabling firewalld..."
systemctl stop firewalld || error_exit "Failed to stop firewalld"
systemctl disable firewalld || error_exit "Failed to disable firewalld"

# 关闭 SELinux
echo "Disabling SELinux..."
sed -i 's/^SELINUX=.*/SELINUX=disabled/' /etc/selinux/config || error_exit "Failed to update SELinux configuration"
setenforce 0 || error_exit "Failed to set SELinux to permissive mode"

# 换源为阿里云源（CentOS 8）
echo "Switching to Aliyun CentOS 8 mirrors..."
wget -O /etc/yum.repos.d/CentOS-Base.repo https://mirrors.aliyun.com/repo/Centos-8.repo || error_exit "Failed to download Aliyun repo file"

# 修改 yum 源
echo "Updating yum sources..."
sed -i 's/mirrorlist/#mirrorlist/g' /etc/yum.repos.d/CentOS-* || error_exit "Failed to update mirrorlist in yum repos"
sed -i 's|#baseurl=http://mirror.centos.org|baseurl=http://vault.centos.org|g' /etc/yum.repos.d/CentOS-* || error_exit "Failed to update baseurl in yum repos"

# 清理并生成缓存
echo "Cleaning and generating yum cache..."
yum clean all || error_exit "Failed to clean yum cache"
yum makecache || error_exit "Failed to generate yum cache"

# 安装并启用服务的通用函数
install_and_enable() {
    local package=$1
    local service=$2

    echo "Installing $package..."
    yum -y install "$package" || error_exit "Failed to install $package"

    echo "Starting and enabling $service..."
    systemctl start "$service" || error_exit "Failed to start $service"
    systemctl enable "$service" || error_exit "Failed to enable $service"
}

# 安装 nginx
install_and_enable "nginx" "nginx.service"

# 安装 PHP 和 PHP-FPM
install_and_enable "php-fpm php*" "php-fpm"

# 修改 php-fpm 配置文件
echo "Configuring PHP-FPM to use nginx user and group..."
sed -i 's/^user = .*/user = nginx/' /etc/php-fpm.d/www.conf || error_exit "Failed to update user in php-fpm config"
sed -i 's/^group = .*/group = nginx/' /etc/php-fpm.d/www.conf || error_exit "Failed to update group in php-fpm config"

# 重启服务
echo "Restarting php-fpm and nginx services..."
systemctl restart php-fpm || error_exit "Failed to restart php-fpm"
systemctl restart nginx || error_exit "Failed to restart nginx"

echo -e "${GREEN}Setup complete!${NC}"