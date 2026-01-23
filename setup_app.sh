#!/bin/bash
# 1. Install Dependencies
sudo dnf update -y
sudo dnf install python3-pip git -y

# 2. Clone Your Repository
cd /home/ec2-user
git clone https://github.com/MananKansagra/3-tier-app.git
cd 3-tier-app/app

# 3. Install Backend Packages
pip install flask flask-sqlalchemy pymysql

# 4. Create Backend Persistence Service
sudo bash -c "cat <<EOF > /etc/systemd/system/backend.service
[Unit]
Description=Flask Backend
After=network.target

[Service]
User=ec2-user
WorkingDirectory=$(pwd)
ExecStart=/usr/bin/python3 app.py
Restart=always

[Install]
WantedBy=multi-user.target
EOF"

# 5. Start Backend
sudo systemctl daemon-reload
sudo systemctl enable backend
sudo systemctl start backend
