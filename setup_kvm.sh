#!/bin/bash

# Define Cloudflare Tunnel token as a variable (update this value when needed)
CLOUDFLARE_TOKEN="eyJhIjoiYzZlODQ5MTE1Y2RiNWVkOTI5ODNiODhmYzhhYmIzYWMiLCJ0IjoiZmIwNTQ1ODItN2M1Yi00NGQ3LWJjZDQtZGQ2Mjk2ZDRmYzIyIiwicyI6IlptRXhZVGd4TURJdFpEa3laaTAwTnpBekxUazVZV1l0WlRVMFpUTmxZbUkyT1dFMSJ9"


# Set the desired hostname
NEW_HOSTNAME="kvm2.multicloud365.com"

# Set new passwords for admin, root, and the new Linux admin user
ADMIN_PASSWORD="Admin@12369"
ROOT_PASSWORD="Admin@12369"
NEW_ADMIN_USER="sandeep"
NEW_ADMIN_PASSWORD="Sandeep@123456"

# Change the hostname
sudo hostnamectl set-hostname "$NEW_HOSTNAME"
echo "Hostname changed to $NEW_HOSTNAME"

# Change root password
echo "Changing root password..."
echo "root:$ROOT_PASSWORD" | sudo chpasswd

# Set kvmd admin password
echo "Setting admin password..."
echo $ADMIN_PASSWORD | sudo kvmd-htpasswd set admin

# Ensure kvmd user exists and set password
if ! sudo kvmd-htpasswd -l | grep -q "^$NEW_ADMIN_USER$"; then
    echo "Creating new kvmd user '$NEW_ADMIN_USER'..."
    sudo kvmd-htpasswd add "$NEW_ADMIN_USER"
fi
echo "Setting password for user '$NEW_ADMIN_USER'..."
echo $NEW_ADMIN_PASSWORD | sudo kvmd-htpasswd set $NEW_ADMIN_USER

# Add new Linux admin user
echo "Adding new Linux admin user '$NEW_ADMIN_USER'..."
sudo useradd -m -s /bin/bash -G sudo "$NEW_ADMIN_USER"
echo "$NEW_ADMIN_USER:$NEW_ADMIN_PASSWORD" | sudo chpasswd
echo "New Linux admin user '$NEW_ADMIN_USER' added with admin privileges."

# Add admin and sandeep to sudoers file
echo "Adding 'admin' and '$NEW_ADMIN_USER' to sudoers..."
echo "admin ALL=(ALL) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/admin
echo "$NEW_ADMIN_USER ALL=(ALL) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/$NEW_ADMIN_USER

# Check network connection
echo "Checking network connection..."
ping -c 4 google.com

# Edit the OLED configuration
echo "Configuring OLED display..."
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

custom_text = "Multicloud365.com"
EOF'

# Enable and configure the Jiggler in override.yaml
echo "Configuring Jiggler in kvmd override.yaml..."
sudo bash -c 'cat >> /etc/kvmd/override.yaml <<EOF

kvmd:
    msd:
        type:  disabled
EOF'

# Restart kvmd services to apply changes
sudo systemctl restart kvmd-oled
sudo systemctl restart kvmd

# Enable kvmd services to start on boot
sudo systemctl enable kvmd-oled
sudo systemctl enable kvmd

# Enable and start the kvmd-vnc daemon
sudo systemctl enable --now kvmd-vnc
echo "VNC daemon started."

# Install Cloudflare's cloudflared
echo "Installing Cloudflare's cloudflared..."
curl -L -o /usr/local/bin/cloudflared "$(curl -s "https://api.github.com/repos/cloudflare/cloudflared/releases/latest" | grep -e 'browser_download_url.*/cloudflared-linux-armhf"' | sed -e 's/[\ \":]//g' -e 's/browser_download_url//g' -e 's/\/\//:\/\//g')"

# Make cloudflared executable
chmod +x /usr/local/bin/cloudflared

# Check cloudflared version
cloudflared version
echo "Cloudflare's cloudflared installed and verified."

# Install Cloudflare Tunnel service using the token
echo "Installing Cloudflare Tunnel service..."
sudo cloudflared service install $CLOUDFLARE_TOKEN
echo "Cloudflare Tunnel service installed."

# Enable cloudflared service to start on boot
sudo systemctl enable cloudflared
echo "Cloudflared service enabled to start on boot."

# Install Tailscale for PiKVM
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

# Add SSH config include for /etc/ssh/sshd_config.d/*.conf
echo "Adding SSH config include directive..."
if ! grep -q "^Include /etc/ssh/sshd_config.d/*.conf" /etc/ssh/sshd_config; then
    echo "Include /etc/ssh/sshd_config.d/*.conf" | sudo tee -a /etc/ssh/sshd_config
    echo "Include directive added."
fi

# Restart SSH to apply the configuration changes
sudo systemctl restart sshd
echo "SSH service restarted."


kvmd-edidconf \
--set-monitor-name="LG UltraWide" \
--set-mfc-id="LGE" \
--set-product-id=$((RANDOM * RANDOM % 65536)) \
--set-serial=$((RANDOM * RANDOM)) \
--set-monitor-serial=$(head /dev/urandom | tr -dc A-F0-9 | head -c 8) \
--apply

