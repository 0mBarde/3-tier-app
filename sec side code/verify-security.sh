#!/bin/bash
# 1. Self-Healing for Suricata
if ! systemctl is-active --quiet suricata; then
    echo "$(date) [RECOVERY] Suricata service was down. Restarting..." >> /var/log/security-audit.log
    sudo systemctl start suricata
    echo "Rollback: sudo systemctl stop suricata" >> /var/log/security-rollback.log
fi

# 2. Self-Healing for Falco
if ! systemctl is-active --quiet falco; then
    echo "$(date) [RECOVERY] Falco service was down. Restarting..." >> /var/log/security-audit.log
    sudo systemctl start falco
fi

