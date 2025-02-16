#!/bin/bash

# Ensure the script is run as root
if [ "$(id -u)" -ne 0 ]; then
  echo "This script must be run as root" 1>&2
  exit 1
fi

echo "Updating package lists..."
apt update

echo "Installing required dependencies (curl, apt-transport-https, ca-certificates)..."
apt install -y curl apt-transport-https ca-certificates

# Add the Plex Media Server official repository
echo "Adding Plex Media Server official repository..."
curl https://downloads.plex.tv/plex-keys/PlexSign.key | sudo apt-key add -
echo "deb https://downloads.plex.tv/repo/deb public main" | sudo tee /etc/apt/sources.list.d/plexmediaserver.list

# Update the package list again to include Plex repository
echo "Updating package lists with Plex repository..."
apt update

# Install Plex Media Server
echo "Installing Plex Media Server..."
apt install -y plexmediaserver

# Ensure the Plex service is enabled and started
echo "Enabling and starting Plex Media Server service..."
systemctl enable plexmediaserver
systemctl start plexmediaserver

# Verify the status of the Plex service
echo "Checking the status of Plex Media Server service..."
systemctl status plexmediaserver --no-pager

# Create content directories in the user's home directory
echo "Creating Plex content directories in the user's home directory..."

user_home=$(eval echo ~$SUDO_USER)  # Get the home directory of the user who ran the script
media_dir="$user_home/PlexMedia"

# Create the media directories for Movies, TV Shows, Music, etc.
mkdir -p "$media_dir/Movies"
mkdir -p "$media_dir/TVShows"
mkdir -p "$media_dir/Music"
mkdir -p "$media_dir/Photos"

# Set appropriate permissions for the directories
chown -R $SUDO_USER:$SUDO_USER "$media_dir"

# Output the directories created
echo "Created the following directories in $user_home/PlexMedia:"
echo "- Movies"
echo "- TVShows"
echo "- Music"
echo "- Photos"

# Output the IP and instructions for accessing Plex
server_ip=$(hostname -I | awk '{print $1}')
echo "Plex Media Server installation complete."
echo "You can access the Plex web interface at: http://$server_ip:32400/web"
echo "Please add your media files to the following directories:"
echo "- $media_dir/Movies"
echo "- $media_dir/TVShows"
echo "- $media_dir/Music"
echo "- $media_dir/Photos"
