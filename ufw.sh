#!/bin/bash

# Ensure the script is run as root
if [ "$(id -u)" -ne 0 ]; then
  echo "This script must be run as root" 1>&2
  exit 1
fi

# Disable UFW logging to prevent log flooding
echo "Disabling UFW logging..."
ufw logging off

# Set default UFW policies to allow all incoming and outgoing traffic
echo "Setting default UFW policies to allow all traffic..."
ufw default allow incoming
ufw default allow outgoing

# Allow all ports and protocols for incoming and outgoing traffic
echo "Allowing all ports (1-65535) for all protocols (TCP/UDP)..."
ufw allow 1:65535/tcp
ufw allow 1:65535/udp

# Enable UFW (if it's not already enabled)
echo "Enabling UFW..."
ufw --force enable

# Display the current UFW status and rules
echo "UFW status and rules:"
ufw status verbose

echo "All ports from 1 to 65535 for both TCP and UDP protocols are now open."
