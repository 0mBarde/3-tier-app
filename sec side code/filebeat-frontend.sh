#!/bin/bash

# --- CONFIGURATION ---
ELK_SERVER_IP="10.0.1.105"  # <--- CHANGE THIS to your ELK Private IP
FALCO_LOG_PATH="/var/log/falco_alerts.json"
MODSEC_LOG_PATH="/var/log/modsec_audit.log"

echo "Starting Filebeat installation and configuration..."

# 1. Install Filebeat via Elastic Repo
rpm --import https://artifacts.elastic.co/GPG-KEY-elasticsearch
cat <<EOF > /etc/yum.repos.d/elastic.repo
[elastic-8.x]
name=Elastic repository for 8.x packages
baseurl=https://artifacts.elastic.co/packages/8.x/yum
gpgcheck=1
gpgkey=https://artifacts.elastic.co/GPG-KEY-elasticsearch
enabled=1
autorefresh=1
type=rpm-md
EOF

yum install filebeat -y

# 2. Configure filebeat.yml
# We are backing up the original and creating a fresh one
mv /etc/filebeat/filebeat.yml /etc/filebeat/filebeat.yml.bak

cat <<EOF > /etc/filebeat/filebeat.yml
filebeat.inputs:
- type: log
  enabled: true
  paths:
    - $FALCO_LOG_PATH
  json.keys_under_root: true
  json.add_error_key: true
  fields:
    log_type: falco

filebeat.config.modules:
  path: \${path.config}/modules.d/*.yml
  reload.enabled: false

# Direct output to Elasticsearch on the remote EC2
output.elasticsearch:
  hosts: ["http://$ELK_SERVER_IP:9200"]
  # If you have SSL/Auth enabled, uncomment and set these:
  # protocol: "https"
  # username: "elastic"
  # password: "your_password"
  # ssl.verification_mode: "none"

setup.kibana:
  host: "$ELK_SERVER_IP:5601"

logging.level: info
EOF

# 3. Enable ModSecurity Module
filebeat modules enable modsecurity

# Configure ModSecurity module paths
cat <<EOF > /etc/yum.repos.d/elastic.repo.tmp # temporary buffer
- module: modsecurity
  audit:
    enabled: true
    var.paths: ["$MODSEC_LOG_PATH"]
EOF
mv /etc/filebeat/modules.d/modsecurity.yml /etc/filebeat/modules.d/modsecurity.yml.bak
cat <<EOF > /etc/filebeat/modules.d/modsecurity.yml
- module: modsecurity
  audit:
    enabled: true
    var.paths: ["$MODSEC_LOG_PATH"]
EOF

# 4. Start and Enable Service
systemctl daemon-reload
systemctl enable filebeat
systemctl restart filebeat

echo "Installation complete. Checking status..."
systemctl status filebeat --no-pager
