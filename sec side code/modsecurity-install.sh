#!/bin/bash

# --- 1. Install Build Dependencies ---
echo "Installing development tools and dependencies..."
sudo dnf groupinstall "Development Tools" -y
sudo dnf install git pcre-devel libxml2-devel curl-devel yajl-devel lmdb-devel wget jq -y

# --- 2. Build libmodsecurity (The Engine) ---
echo "Building libmodsecurity..."
cd /opt
sudo git clone --depth 1 -b v3/master https://github.com/SpiderLabs/ModSecurity
cd ModSecurity
sudo git submodule init
sudo git submodule update
sudo ./build.sh
sudo ./configure
sudo make
sudo make install

# --- 3. Build Nginx Connector ---
echo "Downloading Nginx 1.28.1 source and building connector..."
cd ~
sudo git clone --depth 1 https://github.com/SpiderLabs/ModSecurity-nginx.git
wget http://nginx.org/download/nginx-1.28.1.tar.gz
tar -xzvf nginx-1.28.1.tar.gz
cd nginx-1.28.1

# Configure and build the dynamic module
./configure --with-compat --add-dynamic-module=../ModSecurity-nginx
make modules

# Move module to Nginx directory
sudo mkdir -p /etc/nginx/modules
sudo cp objs/ngx_http_modsecurity_module.so /etc/nginx/modules/

# --- 4. Configure Nginx to Load ModSecurity ---
echo "Configuring Nginx..."
# Add load_module to the top of nginx.conf if not present
if ! grep -q "ngx_http_modsecurity_module.so" /etc/nginx/nginx.conf; then
    sudo sed -i '1i load_module /etc/nginx/modules/ngx_http_modsecurity_module.so;' /etc/nginx/nginx.conf
fi

# --- 5. Setup ModSecurity Config and Rules ---
echo "Setting up OWASP Core Rule Set..."
sudo mkdir -p /etc/nginx/modsec
sudo cp /opt/ModSecurity/modsecurity.conf-recommended /etc/nginx/modsec/modsecurity.conf
sudo cp /opt/ModSecurity/unicode.mapping /etc/nginx/modsec/

# Enable Rule Engine and JSON Logging
sudo sed -i 's/SecRuleEngine DetectionOnly/SecRuleEngine On/' /etc/nginx/modsec/modsecurity.conf
if ! grep -q "SecAuditLogFormat JSON" /etc/nginx/modsec/modsecurity.conf; then
    sudo sed -i '/SecAuditLogType Serial/a SecAuditLogFormat JSON' /etc/nginx/modsec/modsecurity.conf
fi

# Download and Setup OWASP CRS
cd /etc/nginx
sudo git clone https://github.com/coreruleset/coreruleset.git
cd coreruleset
sudo cp crs-setup.conf.example crs-setup.conf

# Create main entry point
sudo bash -c 'cat <<EOF > /etc/nginx/modsec/main.conf
Include /etc/nginx/modsec/modsecurity.conf
Include /etc/nginx/coreruleset/crs-setup.conf
Include /etc/nginx/coreruleset/rules/*.conf
EOF'

# --- 6. Final Restart ---
echo "Verifying Nginx configuration and restarting..."
sudo nginx -t && sudo systemctl restart nginx

echo "Installation Complete! Test with: curl -I 'http://localhost/?test=<script>alert(1)</script>'"
