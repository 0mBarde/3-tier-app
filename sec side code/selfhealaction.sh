#!/bin/bash
ACTION=$1  # quarantine or rate_limit
IP=$2      # Malicious IP
REASON=$3  # e.g., "Falco Unauthorized Shell"

echo "$(date) [PRE-ACTION] $ACTION $IP: $REASON" >> /var/log/security-audit.log

case $ACTION in
    "rate_limit")
        # Limit to 10 packets/minute then drop (Saves internal app traffic)
        sudo iptables -A INPUT -s $IP -m limit --limit 10/minute -j ACCEPT
        sudo iptables -A INPUT -s $IP -j DROP
        echo "Rollback: sudo iptables -D INPUT -s $IP -j DROP" >> /var/log/security-rollback.log
        ;;
    "quarantine")
        sudo iptables -A INPUT -s $IP -j DROP
        # Reversible: Auto-rollback in 1 hour
        echo "sudo iptables -D INPUT -s $IP -j DROP" | sudo at now + 1 hour
        echo "Rollback: sudo iptables -D INPUT -s $IP -j DROP" >> /var/log/security-rollback.log
        ;;
    *)
        echo "Unknown action: $ACTION"
        exit 1
        ;;
esac

