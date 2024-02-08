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

# Function to check if a service is active
is_service_active() 
{
    local service="$1"
    sudo systemctl is-active --quiet $service
}

# Take user input for PHP version
read -p "Enter the PHP version (e.g., 8.2): " original_php_version

# Convert original_php_version to original_php_version_number
original_php_version_number="${original_php_version//./}"

# Reversing Steps

echo -e "${YELLOW}...Stopping and disabling PHP-FPM for PHP $original_php_version${NC}"
sudo systemctl stop php${original_php_version_number}-php-fpm
sudo systemctl disable php${original_php_version_number}-php-fpm

echo -e "${YELLOW}...Removing PHP-FPM systemd service for PHP $original_php_version${NC}"
sudo rm -rf /etc/systemd/system/php${original_php_version_number}-php-fpm.service

echo -e "${YELLOW}...Removing PHP-FPM configuration for PHP $original_php_version${NC}"
sudo rm -rf /etc/php-fpm.d/php${original_php_version_number}-www.conf

echo -e "${YELLOW}...Uninstalling PHP $original_php_version and necessary extensions${NC}"
sudo dnf remove -y php php-cli php-fpm php-mysqlnd php-zip php-devel php-gd php-mbstring php-curl php-xml php-pear php-bcmath php-json

echo -e "${YELLOW}...Disabling PHP $original_php_version module${NC}"
sudo dnf module disable -y php:$original_php_version

echo -e "${YELLOW}...Resetting PHP module${NC}"
sudo dnf module reset -y php

echo -e "${GREEN}...Reversal of PHP Installation Steps Completed${NC}"
