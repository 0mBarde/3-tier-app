#!/bin/bash
# 1. Wait for system locks to release and install packages
sudo dnf update -y
sudo dnf install python3-pip nginx git -y

# 2. Setup directory and clone repository
cd /home/ec2-user
rm -rf 3-tier-app
git clone https://github.com/MananKansagra/3-tier-app.git

# 3. Install requirements into the ec2-user space
# This ensures Streamlit is available at /home/ec2-user/.local/bin/streamlit
sudo -u ec2-user pip3 install -r /home/ec2-user/3-tier-app/frontend/requirements.txt
sudo -u ec2-user pip3 install python-dateutil==2.9.0

# 4. Create Streamlit configuration to allow Nginx proxying
sudo -u ec2-user mkdir -p /home/ec2-user/.streamlit
sudo -u ec2-user cat <<EOF > /home/ec2-user/.streamlit/config.toml
[server]
port = 8501
address = "127.0.0.1"
enableCORS = false
enableXsrfProtection = false
EOF

# 5. Configure Nginx to act as a gateway on Port 80
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

# Fix common Nginx/Amazon Linux conflicts
sudo sed -i 's/listen       80 default_server;/#listen       80 default_server;/' /etc/nginx/nginx.conf
sudo setsebool -P httpd_can_network_connect 1

# 6. Create the "Always On" service
sudo bash -c "cat <<EOF > /etc/systemd/system/frontend.service
[Unit]
Description=Streamlit Frontend Service
After=network.target

[Service]
User=ec2-user
# Point directly to your subfolder
WorkingDirectory=/home/ec2-user/3-tier-app/frontend
Environment=PYTHONPATH=/home/ec2-user/.local/lib/python3.9/site-packages
# Use the absolute path to your file
ExecStart=/home/ec2-user/.local/bin/streamlit run /home/ec2-user/3-tier-app/frontend/frontend.py --server.port 8501 --server.address 127.0.0.1
Restart=always

[Install]
WantedBy=multi-user.target
EOF"

# 7. Reload system and start all tiers
sudo systemctl daemon-reload
sudo systemctl enable nginx frontend
sudo systemctl restart nginx
sudo systemctl start frontend
