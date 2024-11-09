#!/bin/bash

# Update system packages
# sudo apt update && sudo apt upgrade -y
sudo apt update

# Install Nginx
sudo apt install nginx -y

# Enable Nginx to start on boot
sudo systemctl enable nginx
sudo systemctl start nginx

# Install PHP 8.1 and required extensions for PHP-FPM
sudo apt install software-properties-common -y
sudo add-apt-repository ppa:ondrej/php -y
sudo apt update
sudo apt install php8.1-fpm php8.1-mysql php8.1-cli php8.1-curl php8.1-gd php8.1-mbstring php8.1-xml php8.1-zip -y

# Verify PHP installation
# php -v

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

# Adjust PHP-FPM settings for maximum memory use
PHP_FPM_CONF="/etc/php/8.1/fpm/php.ini"
sudo cp $PHP_FPM_CONF $PHP_FPM_CONF.backup

# Optimize PHP settings
sudo sed -i "s/^memory_limit = .*/memory_limit = 256M/" $PHP_FPM_CONF
sudo sed -i "s/^upload_max_filesize = .*/upload_max_filesize = 10M/" $PHP_FPM_CONF
sudo sed -i "s/^post_max_size = .*/post_max_size = 10M/" $PHP_FPM_CONF
sudo sed -i "s/^max_execution_time = .*/max_execution_time = 120/" $PHP_FPM_CONF
sudo sed -i "s/^max_input_time = .*/max_input_time = 120/" $PHP_FPM_CONF
sudo sed -i "s/^max_input_vars = .*/max_input_vars = 3000/" $PHP_FPM_CONF
sudo sed -i "s|;date.timezone =.*|date.timezone = Asia/Jakarta|" $PHP_FPM_CONF

# Restart PHP-FPM to apply changes
sudo systemctl restart php8.1-fpm

# Backup the current MariaDB configuration
sudo cp /etc/mysql/mariadb.conf.d/50-server.cnf /etc/mysql/mariadb.conf.d/50-server.cnf.backup

# Add memory optimization settings for MariaDB
cat <<EOF | sudo tee -a /etc/mysql/my.cnf
[mysqld]
# Allocate InnoDB buffer pool
innodb_buffer_pool_size = 512M

# Log buffer size for transactional workloads
innodb_log_buffer_size = 64M

# Disable query cache (as per modern best practices)
query_cache_size = 0
query_cache_limit = 0

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

# Configure Nginx to use PHP-FPM
sudo bash -c 'cat <<EOF > /etc/nginx/sites-available/default
server {
    listen 80;
    server_name _;

    root /var/www/html;
    index index.php index.html index.htm;

    location / {
        try_files \$uri \$uri/ =404;
    }

    location ~ \.php\$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/run/php/php8.1-fpm.sock;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        include fastcgi_params;
    }

    location ~ /\.ht {
        deny all;
    }
}
EOF'

# Restart Nginx to apply the configuration
sudo systemctl restart nginx

# Install glances for monitoring system resources
sudo apt install glances -y

echo "Starter stack installed successfully!"
