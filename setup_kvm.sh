#!/bin/bash

# Set Wi-Fi credentials
WIFI_SSID="YourWiFiSSID"
WIFI_PASSWORD="YourWiFiPassword"

# Set the desired hostname (change "YourDesiredHostname" to your actual hostname)
NEW_HOSTNAME="kvm2.multicloud365.com"

# Set new passwords for admin, root, and the new Linux admin user
ADMIN_PASSWORD="Admin@12369"
ROOT_PASSWORD="Admin@12369"
NEW_ADMIN_USER="Sandeep"
NEW_ADMIN_PASSWORD="Sandeep@123456"

# Set or change another kvmd user password using kvmd-htpasswd
USER="Sandeep"
USER_PASSWORD="Sandeep@123456"

# Change the hostname
sudo hostnamectl set-hostname "$NEW_HOSTNAME"
echo "Hostname changed to $NEW_HOSTNAME"

# Change root password
echo "Changing root password..."
echo "root:$ROOT_PASSWORD" | sudo chpasswd

# Use kvmd-htpasswd to set the admin password
echo "Setting admin password..."
echo $ADMIN_PASSWORD | sudo kvmd-htpasswd set admin

# Ensure user exists before setting password
if ! sudo kvmd-htpasswd -l | grep -q "^$NEW_ADMIN_USER$"; then
    echo "Creating new kvmd user '$NEW_ADMIN_USER'..."
    sudo kvmd-htpasswd add "$NEW_ADMIN_USER"
fi
echo "Setting password for user '$NEW_ADMIN_USER'..."
echo $NEW_ADMIN_PASSWORD | sudo kvmd-htpasswd set $NEW_ADMIN_USER

# Add a new Linux admin user
echo "Adding new admin user '$NEW_ADMIN_USER'..."
sudo useradd -m -s /bin/bash -G sudo "$NEW_ADMIN_USER"

# Set the password for the new Linux admin user
echo "$NEW_ADMIN_USER:$NEW_ADMIN_PASSWORD" | sudo chpasswd
echo "New Linux admin user '$NEW_ADMIN_USER' added with admin privileges."

# Install WiFi tools
echo "Installing WiFi tools..."
sudo pacman -S --noconfirm wpa_supplicant wireless_tools dhclient

# Enable WiFi interface (assuming wlan0 as the interface)
echo "Enabling WiFi interface..."
sudo ip link set wlan0 up

# Connect to WiFi network
echo "Connecting to WiFi network '$WIFI_SSID'..."
sudo wpa_passphrase "$WIFI_SSID" "$WIFI_PASSWORD" | sudo tee /etc/wpa_supplicant/wpa_supplicant.conf

# Start wpa_supplicant
sudo systemctl start wpa_supplicant@wlan0.service

# Obtain IP address via DHCP
sudo dhclient wlan0

# Check network connection
echo "Checking network connection..."
ping -c 4 google.com

# Edit the OLED configuration
sudo bash -c 'cat > /etc/kvmd/oled.conf <<EOF
[oled]
enabled = true
layout = custom
refresh_interval = 5
brightness = 150

custom_layout = {
    "row_1": "PiKVM V3 - {hostname}",
    "row_2": "Uptime: {uptime}",
    "row_3": "IP: {ip}",
    "row_4": "Temp: {cpu_temp}°C",
    "row_5": "Speed: {network_speed} Mbps"
}

custom_text = "Secure KVM Console"
EOF'

# Edit the override.yaml configuration to enable the Jiggler
sudo bash -c 'cat >> /etc/kvmd/override.yaml <<EOF
kvmd:
    hid:
        jiggler:
            enabled: true
            active: true
EOF'

# Restart the kvmd-oled service to apply OLED changes
sudo systemctl restart kvmd-oled

# Restart the kvmd service to apply Jiggler changes
sudo systemctl restart kvmd

# Enable and start the kvmd-vnc daemon
sudo systemctl enable --now kvmd-vnc

echo "Hostname changed, OLED configuration updated, Jiggler enabled, and VNC daemon started."

# Install Cloudflare's cloudflared
echo "Installing Cloudflare's cloudflared..."
curl -L -o /usr/local/bin/cloudflared "$(curl -s "https://api.github.com/repos/cloudflare/cloudflared/releases/latest" | grep -e 'browser_download_url.*/cloudflared-linux-armhf"' | sed -e 's/[\ \":]//g' -e 's/browser_download_url//g' -e 's/\/\//:\/\//g')"

# Make cloudflared executable
chmod +x /usr/local/bin/cloudflared

# Check cloudflared version
cloudflared version
echo "Cloudflare's cloudflared installed and verified."

# Install Cloudflare Tunnel service using provided token
echo "Installing Cloudflare Tunnel service..."
sudo cloudflared service install eyJhIjoiYzZlODQ5MTE1Y2RiNWVkOTI5ODNiODhmYzhhYmIzYWMiLCJ0IjoiYzE2OTI2YjctYjQwYy00MmJkLThiNWUtMzhkMDQ4M2U5MDkwIiwicyI6Ik5EVTRZbVV3WWpNdFpERm1NUzAwTkdRMExUbGtNVFl0TkdZM01EazFOR1EzTWpKaSJ9
echo "Cloudflare Tunnel service installed."

# Enable cloudflared service to start on boot
sudo systemctl enable cloudflared
echo "Cloudflared service enabled to start on boot."

# Install Tailscale
echo "Installing Tailscale for PiKVM..."

# Check if a pacman lock file exists, remove it if present
if [ -f /var/lib/pacman/db.lck ]; then
    echo "Removing pacman lock file..."
    sudo rm /var/lib/pacman/db.lck
fi

# Update package database and upgrade existing packages
sudo pacman -Syu --noconfirm

# Install Tailscale for PiKVM
sudo pacman -S tailscale-pikvm --noconfirm

# Enable and start Tailscale service
sudo systemctl enable --now tailscaled

# Authenticate and bring up Tailscale network
echo "Bringing up Tailscale network..."
sudo tailscale up

echo "Tailscale installed and network brought up."
