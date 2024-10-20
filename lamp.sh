#!/bin/bash

# Update system packages
sudo apt update && sudo apt upgrade -y

# Install Apache
sudo apt install apache2 -y

# Enable Apache to start on boot
sudo systemctl enable apache2
sudo systemctl start apache2

# Install PHP 8.1 and required extensions
sudo apt install software-properties-common -y
sudo add-apt-repository ppa:ondrej/php -y
sudo apt update
sudo apt install php8.1 libapache2-mod-php8.1 php8.1-mysql php8.1-cli php8.1-curl php8.1-gd php8.1-mbstring php8.1-xml php8.1-zip -y

# Verify PHP installation
php -v

# Install MariaDB
sudo apt install mariadb-server -y

# Secure MariaDB installation
sudo mysql_secure_installation

# Enable MariaDB to start on boot
sudo systemctl enable mariadb
sudo systemctl start mariadb

# Create a database and user (optional, replace values as needed)
DB_NAME="toefl"
DB_USER="toefl"
DB_PASS="dragonballz"
sudo mysql -e "CREATE DATABASE $DB_NAME;"
sudo mysql -e "CREATE USER '$DB_USER'@'localhost' IDENTIFIED BY '$DB_PASS';"
sudo mysql -e "GRANT ALL PRIVILEGES ON $DB_NAME.* TO '$DB_USER'@'localhost';"
sudo mysql -e "FLUSH PRIVILEGES;"

# Adjust Apache configuration (optional)
sudo a2enmod rewrite
sudo systemctl restart apache2

# Backup php.ini before making changes
sudo cp /etc/php/8.1/apache2/php.ini /etc/php/8.1/apache2/php.ini.backup

# Optimize PHP settings for maximum memory use
sudo sed -i "s/^memory_limit = .*/memory_limit = 512M/" /etc/php/8.1/apache2/php.ini
sudo sed -i "s/^upload_max_filesize = .*/upload_max_filesize = 100M/" /etc/php/8.1/apache2/php.ini
sudo sed -i "s/^post_max_size = .*/post_max_size = 100M/" /etc/php/8.1/apache2/php.ini
sudo sed -i "s/^max_execution_time = .*/max_execution_time = 600/" /etc/php/8.1/apache2/php.ini
sudo sed -i "s/^max_input_time = .*/max_input_time = 600/" /etc/php/8.1/apache2/php.ini
sudo sed -i "s/^max_input_vars = .*/max_input_vars = 3000/" /etc/php/8.1/apache2/php.ini
sudo sed -i "s|;date.timezone =.*|date.timezone = Asia/Jakarta|" /etc/php/8.1/apache2/php.ini

# Restart Apache to apply PHP changes
sudo systemctl restart apache2

# Backup the current MariaDB configuration
sudo cp /etc/mysql/mariadb.conf.d/50-server.cnf /etc/mysql/mariadb.conf.d/50-server.cnf.backup

# Add memory optimization settings for MariaDB
cat <<EOF | sudo tee /etc/mysql/mariadb.conf.d/99-max-memory.cnf
[mysqld]
# Allocate 1GB (1024MB) to InnoDB buffer pool
innodb_buffer_pool_size = 1024M

# Log buffer size for transactional workloads
innodb_log_buffer_size = 16M

# Enable query cache to speed up repeated queries
query_cache_size = 64M
query_cache_limit = 2M

# Increase temporary table size
tmp_table_size = 64M
max_heap_table_size = 64M

# Allow more connections while balancing memory
max_connections = 150

# Optimize table cache size for better performance
table_open_cache = 400
EOF

# Restart MariaDB to apply changes
sudo systemctl restart mariadb

# Optimize Apache for 2GB RAM by limiting processes
cat <<EOF | sudo tee /etc/apache2/conf-available/optimization.conf
<IfModule mpm_prefork_module>
    StartServers         2
    MinSpareServers      2
    MaxSpareServers      5
    MaxRequestWorkers    75
    MaxConnectionsPerChild 1000
</IfModule>
EOF

# Enable Apache optimization and restart
sudo a2enconf optimization
sudo systemctl restart apache2

# Install glances for monitoring system resources
sudo apt install glances -y

# Final check of services status
# sudo systemctl status apache2
# sudo systemctl status mariadb

echo "LAMP stack installed successfully with optimized PHP 8.1, MariaDB settings, and Glances for system monitoring!"
