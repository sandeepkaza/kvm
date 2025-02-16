#!/bin/bash

# Ensure the script is run as root
if [ "$(id -u)" -ne 0 ]; then
  echo "This script must be run as root" 1>&2
  exit 1
fi

echo "Updating package lists and upgrading the system..."
pacman -Syu --noconfirm

# Install LXQt, SDDM, and other necessary components
echo "Installing LXQt, SDDM, and dependencies..."
pacman -S --noconfirm lxqt sddm libglvnd ttf-dejavu

# Enable and start SDDM (Simple Desktop Display Manager)
echo "Enabling and starting SDDM..."
systemctl enable sddm --now

# Check if yay is installed, if not, install it
if ! command -v yay &> /dev/null; then
  echo "Installing yay (AUR helper)..."
  pacman -S --needed --noconfirm git base-devel
  USER_HOME=$(eval echo ~$SUDO_USER)
  
  # Clone and build yay as a non-root user
  sudo -u "$SUDO_USER" git clone https://aur.archlinux.org/yay.git "$USER_HOME/yay"
  cd "$USER_HOME/yay"
  sudo -u "$SUDO_USER" makepkg -si --noconfirm
  cd -
fi

# Install XRDP from AUR using yay
echo "Installing XRDP from AUR..."
sudo -u "$SUDO_USER" yay -S --noconfirm xrdp

# Enable and start XRDP
echo "Enabling and starting XRDP..."
systemctl enable xrdp --now

# Configure XRDP to start LXQt
echo "Configuring XRDP to start LXQt..."
echo "startlxqt" > ~/.xsession
chmod +x ~/.xsession

# Set the user's password
echo "Setting a new password for the current user..."
passwd

# Configure iptables to allow RDP on port 3389
echo "Configuring iptables to allow RDP on port 3389..."
iptables -A INPUT -p tcp --dport 3389 -j ACCEPT

# Restart xrdp service to apply changes
echo "Restarting XRDP service..."
systemctl restart xrdp

echo "Setup completed. You can now connect to this machine via XRDP on port 3389."
