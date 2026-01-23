#!/bin/bash
# 1. System Updates and Packages
sudo dnf update -y
sudo dnf install python3-pip nginx git -y

# 2. Clone Your Repository
cd /home/ec2-user
git clone https://github.com/MananKansagra/3-tier-app.git
cd 3-tier-app/frontend

# 3. Install Requirements & Fix Version Conflict
pip install -r requirements.txt
pip install --user python-dateutil==2.9.0

# 4. Configure Streamlit Environment
mkdir -p ~/.streamlit
cat <<EOF > ~/.streamlit/config.toml
[server]
port = 8501
address = "127.0.0.1"
enableCORS = false
enableXsrfProtection = false
EOF

# 5. Nginx Reverse Proxy Setup
sudo bash -c 'cat <<EOF > /etc/nginx/conf.d/streamlit_app.conf
server {
    listen 80 default_server;
    server_name _;
    location / {
        proxy_pass http://127.0.0.1:8501/;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$host;
    }
}
EOF'

# Remove Nginx default server conflict and allow network connections
sudo sed -i 's/listen       80 default_server;/#listen       80 default_server;/' /etc/nginx/nginx.conf
sudo setsebool -P httpd_can_network_connect 1

# 6. Create Frontend Persistence Service
sudo bash -c "cat <<EOF > /etc/systemd/system/frontend.service
[Unit]
Description=Streamlit Frontend
After=network.target

[Service]
User=ec2-user
WorkingDirectory=$(pwd)
ExecStart=/home/ec2-user/.local/bin/streamlit run /home/ec2-user/3-tier-app/frontend/fronend.py --server.port 8501 --server.address 127.0.0.1
Restart=always

[Install]
WantedBy=multi-user.target
EOF"

# 7. Enable and Start
sudo systemctl daemon-reload
sudo systemctl enable nginx frontend
sudo systemctl restart nginx
sudo systemctl start frontend
