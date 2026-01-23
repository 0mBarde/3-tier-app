#!/bin/bash
# 1. Install MariaDB Service
sudo dnf install mariadb105-server -y
sudo systemctl enable --now mariadb

# 2. Database & User Configuration
# Replace 10.0.2.% with your actual App Subnet CIDR if different
APP_SUBNET="10.0.2.%" 

sudo mariadb -e "CREATE DATABASE IF NOT EXISTS university_db;"
sudo mariadb -e "CREATE USER IF NOT EXISTS 'admin_user'@'$APP_SUBNET' IDENTIFIED BY 'SecurePassword123';"
sudo mariadb -e "GRANT ALL PRIVILEGES ON university_db.* TO 'admin_user'@'$APP_SUBNET';"
sudo mariadb -e "FLUSH PRIVILEGES;"

# 3. Initialize Schema
sudo mariadb -D university_db -e "
CREATE TABLE IF NOT EXISTS students (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(120) UNIQUE NOT NULL,
    department VARCHAR(100),
    gpa FLOAT DEFAULT 0.0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);"
