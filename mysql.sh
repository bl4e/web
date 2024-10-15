# 替换为阿里云的 CentOS 8 源
curl -o /etc/yum.repos.d/CentOS-Base.repo https://mirrors.aliyun.com/repo/Centos-8.repo
sed -i 's/mirrorlist/#mirrorlist/g' /etc/yum.repos.d/CentOS-*
sed -i 's|#baseurl=http://mirror.centos.org|baseurl=http://vault.centos.org|g' /etc/yum.repos.d/CentOS-*

# 清理缓存并生成新的缓存
yum clean all
yum makecache fast
if [ $? -ne 0 ]; then
    echo "makecache 失败，请检查网络或源配置。"
    exit 1
fi

# 安装 MariaDB 和 MariaDB 服务器
yum -y install mariadb mariadb-server
if [ $? -ne 0 ]; then
    echo "MariaDB 安装失败"
    exit 1
fi

# 启动并设置 MariaDB 开机自启
systemctl enable --now mariadb.service
if [ $? -ne 0 ]; then
    echo "MariaDB 启动失败"
    exit 1
fi

# 关闭并禁用 firewalld
systemctl stop firewalld
systemctl disable firewalld

# 禁用 SELinux
sed -i 's/SELINUX=enforcing/SELINUX=disabled/' /etc/selinux/config
setenforce 0

# 设置 MariaDB root 用户密码
mysqladmin -u root password '123.bmk'
if [ $? -ne 0 ]; then
    echo "设置 MariaDB root 密码失败"
    exit 1
fi

# 允许远程连接并刷新权限
mysql -u root -p'123.bmk' -e "GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' IDENTIFIED BY '123.bmk' WITH GRANT OPTION; FLUSH PRIVILEGES;"
if [ $? -ne 0 ]; then
    echo "MySQL 权限设置失败"
    exit 1
fi