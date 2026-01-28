#!/bin/bash
# 1. Installing Dependencies
sudo dnf update -y
sudo dnf install python3-pip git -y

# 2. Cloning the Repository
cd /home/ec2-user
rm -rf 3-tier-app 
git clone https://github.com/MananKansagra/3-tier-app.git
cd 3-tier-app/app

# 3. Installing Backend Packages
pip3 install flask flask-sqlalchemy pymysql cryptography

# 4. Creating Backend Persistence Service
sudo bash -c "cat <<EOF > /etc/systemd/system/backend.service
[Unit]
Description=Flask Backend
After=network.target

[Service]
User=ec2-user
WorkingDirectory=$(pwd)
ExecStart=/usr/bin/python3 app.py
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF"

# 5. Starting Backend
sudo systemctl daemon-reload
sudo systemctl enable backend
sudo systemctl start backend

# 6. Waiting until the service is actually "active"
echo "Verifying backend service status..."
MAX_RETRIES=10
RETRY_COUNT=0

while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
    STATUS=$(systemctl is-active backend)
    if [ "$STATUS" = "active" ]; then
        echo "Backend service is running successfully."
        exit 0
    else
        echo "Backend is $STATUS. Retrying start... ($((RETRY_COUNT+1))/$MAX_RETRIES)"
        sudo systemctl restart backend
        sleep 10
        RETRY_COUNT=$((RETRY_COUNT+1))
    fi
done

echo "Error: Backend service failed to start after $MAX_RETRIES attempts."
# Checking logs if it fails
sudo journalctl -u backend --no-pager | tail -n 20
exit 1
