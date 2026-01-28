#!/bin/bash

# --- CONFIGURATION ---
ELK_SERVER_IP="10.0.1.105"
FALCO_LOG="/var/log/falco_alerts.json"
SURICATA_LOG="/var/log/suricata/eve.json"

echo "Step 1: Installing Filebeat..."
# Import GPG Key and add Elastic Repository for AL2023
sudo rpm --import https://artifacts.elastic.co/GPG-KEY-elasticsearch
sudo tee /etc/yum.repos.d/elastic.repo <<EOF
[elastic-8.x]
name=Elastic repository for 8.x packages
baseurl=https://artifacts.elastic.co/packages/8.x/yum
gpgcheck=1
gpgkey=https://artifacts.elastic.co/GPG-KEY-elasticsearch
enabled=1
autorefresh=1
type=rpm-md
EOF

sudo dnf install filebeat -y

echo "Step 2: Configuring Filebeat YAML..."
# Overwrite the config with the correct grouped input structure
sudo tee /etc/filebeat/filebeat.yml <<EOF
filebeat.inputs:
# --- Falco Logs ---
- type: log
  enabled: true
  paths:
    - $FALCO_LOG
  json.keys_under_root: true
  json.add_error_key: true
  fields:
    log_type: falco

# --- Suricata Logs ---
- type: log
  enabled: true
  paths:
    - $SURICATA_LOG
  json.keys_under_root: true
  json.add_error_key: true
  fields:
    log_type: suricata

output.logstash:
  hosts: ["$ELK_SERVER_IP:5044"]

logging.level: info
EOF

echo "Step 3: Setting Permissions & Starting Service..."
# Ensure Filebeat can read the log files
sudo chmod 644 $FALCO_LOG
sudo chmod 644 $SURICATA_LOG

# Enable and start services
sudo systemctl daemon-reload
sudo systemctl enable filebeat
sudo systemctl restart filebeat

echo "--- Verification ---"
sudo filebeat test config
sudo systemctl status filebeat --no-pager
