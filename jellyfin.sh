#!/bin/bash

# Ensure the script is run as root
if [ "$(id -u)" -ne 0 ]; then
  echo "This script must be run as root" 1>&2
  exit 1
fi

echo "Updating package lists..."
apt update

echo "Installing required dependencies (curl, apt-transport-https, software-properties-common)..."
apt install -y curl apt-transport-https software-properties-common

# Add Jellyfin's GPG key and repository
echo "Adding Jellyfin repository..."
curl -fsSL https://repo.jellyfin.org/ubuntu/jellyfin_team.gpg.key | sudo tee /usr/share/keyrings/jellyfin.gpg.key > /dev/null
echo "deb [signed-by=/usr/share/keyrings/jellyfin.gpg.key] https://repo.jellyfin.org/ubuntu $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/jellyfin.list

# Update package list again to include Jellyfin repository
echo "Updating package lists with Jellyfin repository..."
apt update

# Install Jellyfin
echo "Installing Jellyfin Media Server..."
apt install -y jellyfin

# Ensure the Jellyfin service is enabled and started
echo "Enabling and starting Jellyfin service..."
systemctl enable jellyfin
systemctl start jellyfin

# Verify the status of the Jellyfin service
echo "Checking the status of Jellyfin service..."
systemctl status jellyfin --no-pager

# Output the IP and instructions for accessing Jellyfin
server_ip=$(hostname -I | awk '{print $1}')
echo "Jellyfin Media Server installation complete."
echo "You can access the Jellyfin web interface at: http://$server_ip:8096"

