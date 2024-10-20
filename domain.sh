#!/bin/bash

DOMAIN="domainname"

# Install certbot and the Apache plugin for certbot
sudo apt install -y certbot python3-certbot-apache

# Create the directory for the domain
sudo mkdir -p /var/www/html/$DOMAIN/public_html

# Change ownership of the directory
sudo chown -R $USER:$USER /var/www/html/$DOMAIN/public_html

# Create the Apache configuration file for the domain
sudo bash -c "cat > /etc/apache2/sites-available/$DOMAIN.conf << 'EOF'
<VirtualHost *:80>
    ServerAdmin admin@$DOMAIN
    ServerName $DOMAIN
    ServerAlias www.$DOMAIN
    DocumentRoot /var/www/html/$DOMAIN/public_html

    <Directory /var/www/html/$DOMAIN/public_html>
        Options Indexes FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>

    ErrorLog \${APACHE_LOG_DIR}/$DOMAIN-error.log
    CustomLog \${APACHE_LOG_DIR}/$DOMAIN-access.log combined
</VirtualHost>
EOF"

# Enable the new site and the rewrite module
sudo a2ensite $DOMAIN.conf
sudo a2enmod rewrite

# Restart Apache to apply changes
sudo systemctl restart apache2

# Obtain SSL certificate using certbot
sudo certbot --apache -d $DOMAIN
