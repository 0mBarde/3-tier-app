#!/bin/bash

# --- Configuration Variables ---
ALERTS_FILE="/var/log/falco_alerts.json"

# 1. Ensure root privileges
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root (use sudo)"
   exit 1
fi

echo "--- Step 1: Configuring Official Falco Repositories ---"
rpm --import https://falco.org/repo/falcosecurity-packages.asc
curl -s -o /etc/yum.repos.d/falcosecurity.repo https://falco.org/repo/falcosecurity-rpm.repo
yum update -y

echo "--- Step 2: Installing Falco Package ---"
# Note: Modern eBPF does not require kernel headers or dkms
yum install -y falco

echo "--- Step 3: Configuring falco.yaml for eBPF & JSON Output ---"
# Set engine to modern_ebpf (uses engine.kind key in modern versions)
sed -i 's/kind: .*/kind: modern_ebpf/' /etc/falco/falco.yaml

# Enable JSON output for ELK compatibility
sed -i 's/^json_output: .*/json_output: true/' /etc/falco/falco.yaml

# Configure the file_output block properly (enabling and setting path)
# This specifically targets the file_output section to avoid mis-alignment
sed -i '/file_output:/,/filename:/ { s/enabled: .*/enabled: true/; s|filename: .*|filename: '$ALERTS_FILE'| }' /etc/falco/falco.yaml

echo "--- Step 4: Starting the Modern BPF Service ---"
# On Amazon Linux, systemctl prefers the specific unit over the alias
systemctl daemon-reload
systemctl enable --now falco-modern-bpf

echo "--- Step 5: Verification ---"
# Clear any initial plain-text startup logs to prevent 'jq' parse errors
truncate -s 0 $ALERTS_FILE 

if systemctl is-active --quiet falco-modern-bpf; then
    echo "SUCCESS: Falco is running with Modern eBPF."
    echo "JSON alerts are being written to: $ALERTS_FILE"
else
    echo "ERROR: Falco failed to start. Check 'journalctl -u falco-modern-bpf'"
    exit 1
fi
