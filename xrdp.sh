#!/bin/bash

# Ensure the script is run as root
if [ "$(id -u)" -ne 0 ]; then
  echo "This script must be run as root" 1>&2
  exit 1
fi

echo "Updating package lists..."
apt update

echo "Installing LXQt, SDDM, and XRDP..."
apt install -y lxqt sddm xrdp

# Create or update the iptables rules to allow XRDP on port 3389
echo "Configuring iptables to allow XRDP on port 3389..."
iptables_rule_file="/etc/iptables/rules.v4"
if ! grep -q "dport 3389" "$iptables_rule_file"; then
  echo "-A INPUT -p tcp -m state --state NEW -m tcp --dport 3389 -j ACCEPT" >> "$iptables_rule_file"
  echo "Restoring iptables rules..."
  iptables-restore < "$iptables_rule_file"
else
  echo "XRDP rule already exists in iptables configuration."
fi

# Ensure iptables-persistent is installed to save iptables rules on reboot
if ! dpkg -l | grep -q iptables-persistent; then
  echo "Installing iptables-persistent to save iptables rules..."
  apt install -y iptables-persistent
fi

# Set up the .xsession file for XRDP to use LXQt
echo "Configuring XRDP to start LXQt..."
echo "startlxqt" > ~/.xsession

# Set the user's password
echo "Setting a new password for the current user..."
passwd

echo "Setup completed. You can now connect to this machine via XRDP on port 3389."
