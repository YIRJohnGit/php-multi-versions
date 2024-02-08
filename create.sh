#!/bin/bash

# Color Settings
RED='\033[0;31m' # Red colored text
NC='\033[0m' # Normal text
YELLOW='\033[33m' # Yellow Color
GREEN='\033[32m' # Green Color

# Function to handle errors
handle_error() 
{
    local error_message="$1"
    echo -e "${RED}Error: $error_message${NC}"
    exit 1
}

# Function to check if a port is in use
is_port_in_use() 
{
    local port="$1"
    lsof -i :$port >/dev/null 2>&1
}

# Take user input for PHP version
read -p "Enter the PHP version (e.g., 8.2): " php_version
php_version_number="${php_version//./}"

echo -e "${YELLOW}...Check if the specified port is in use${NC}"
if is_port_in_use "90${php_version}"; then
    handle_error "Port 90${php_version} is already in use. Please choose a different port."
fi

echo -e "${YELLOW}...enable Remi repository${NC}"
sudo dnf install -y epel-release
sudo dnf install -y https://rpms.remirepo.net/enterprise/remi-release-8.rpm
sudo dnf config-manager --set-enabled remi

echo -e "${YELLOW}...Enable the PHP $php_version module${NC}"
sudo dnf module enable -y php:$php_version
if [ $? -ne 0 ]; then
    handle_error "Failed to enable PHP $php_version module."
fi

echo -e "${YELLOW}...Install PHP $php_version and necessary extensions${NC}"
sudo dnf install -y php php-cli php-fpm php-mysqlnd php-zip php-devel php-gd php-mbstring php-curl php-xml php-pear php-bcmath php-json php-intl
if [ $? -ne 0 ]; then
    handle_error "Failed to install PHP $php_version and extensions."
fi

echo -e "${YELLOW}...Create PHP-FPM configuration for PHP $php_version${NC}"
sudo cp /etc/php-fpm.d/www.conf /etc/php-fpm.d/php${php_version_number}-www.conf
sudo sed -i "s/^listen = .*/listen = 127.0.0.1:90${php_version_number}/" /etc/php-fpm.d/php${php_version_number}-www.conf
sudo sed -i 's/^user = .*/user = apache/' /etc/php-fpm.d/php${php_version_number}-www.conf
sudo sed -i 's/^group = .*/group = apache/' /etc/php-fpm.d/php${php_version_number}-www.conf

echo -e "${YELLOW}...Create PHP-FPM systemd service for PHP $php_version${NC}"
echo "
[Unit]
Description=The PHP FastCGI Process Manager for PHP $php_version
After=network.target

[Service]
Type=simple
ExecStart=/usr/sbin/php-fpm --nodaemonize --fpm-config /etc/php-fpm.d/php${php_version_number}-www.conf
ExecReload=/bin/kill -USR2 \$MAINPID

[Install]
WantedBy=multi-user.target
" | sudo tee /etc/systemd/system/php${php_version_number}-php-fpm.service

echo -e "${YELLOW}...Start and enable PHP-FPM for PHP $php_version${NC}"
sudo systemctl start php${php_version_number}-php-fpm
if [ $? -ne 0 ]; then
    handle_error "Failed to start PHP-FPM for PHP $php_version."
fi

sudo systemctl enable php${php_version_number}-php-fpm
if [ $? -ne 0 ]; then
    handle_error "Failed to Enable PHP-FPM for PHP $php_version."
fi

echo -e "${YELLOW}...Check PHP-FPM status for PHP $php_version${NC}"
sudo systemctl status php${php_version_number}-php-fpm
if [ $? -ne 0 ]; then
    handle_error "Failed to start PHP-FPM for PHP $php_version."
else
    echo -e "${GREEN}...Successfully completed PHP installation. Please do patching.${NC}"
    echo -e "${YELLOW}J:\devops_working_directory\YIR_DevOps_v02\bashscripts\apache_configuration\httpd.sh${NC}"
fi
