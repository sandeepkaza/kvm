#!/bin/bash

# Define variables
AWX_REPO="https://github.com/ansible/awx.git"
DOCKER_COMPOSE_VERSION="1.29.2"
AWX_DIR="awx"
AWX_ADMIN_PASSWORD="Admin@12369"  # Change this to your desired password

# Update and upgrade the system
echo "Updating and upgrading the system..."
sudo apt update && sudo apt upgrade -y

# Install required packages
echo "Installing required packages..."
sudo apt install -y git curl wget unzip python3-pip python3-dev build-essential python3-venv

# Install Docker
echo "Installing Docker..."
sudo apt install -y docker.io
sudo systemctl enable --now docker
sudo usermod -aG docker $USER
echo "Docker installed successfully."

# Install Docker Compose
echo "Installing Docker Compose..."
sudo curl -L "https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
echo "Docker Compose installed successfully."

# Set up a Python virtual environment for Ansible installation
echo "Setting up Python virtual environment..."
if [ ! -d "/home/ubuntu/awx-venv" ]; then
  python3 -m venv /home/ubuntu/awx-venv
fi

# Activate the virtual environment
source /home/ubuntu/awx-venv/bin/activate

# Install Ansible in the virtual environment
echo "Installing Ansible..."
pip install ansible
echo "Ansible installed successfully."

# Clone the AWX repository only if the directory doesn't exist
if [ ! -d "$AWX_DIR" ]; then
  echo "Cloning the AWX repository..."
  git clone $AWX_REPO
else
  echo "AWX directory already exists, skipping clone."
fi

cd $AWX_DIR

# Now, let's check the repository structure for the installer
if [ ! -d "docker-compose" ]; then
  echo "Error: docker-compose directory not found. The structure might have changed."
  exit 1
fi

# Navigate to the docker-compose directory
cd docker-compose

# Create .env file if it doesn't exist and configure AWX settings
echo "Configuring AWX environment variables..."

if [ ! -f ".env" ]; then
  cp .env.sample .env
fi

# Update .env file with custom settings, like admin password
echo "Setting AWX admin password..."
sed -i "s/^#AWX_ADMIN_PASSWORD=.*/AWX_ADMIN_PASSWORD=$AWX_ADMIN_PASSWORD/" .env

# (Optional) Modify other settings in the .env file as needed (ports, database, etc.)
# You can add or uncomment lines based on your setup needs

# Run Docker Compose to start AWX
echo "Starting AWX using Docker Compose..."
sudo docker-compose up -d

# Wait a few seconds for containers to start
sleep 10

# Verify that AWX containers are running
echo "Verifying AWX containers..."
sudo docker-compose ps

# Display access information
echo "AWX setup complete! You can now access AWX via http://localhost with the following credentials:"
echo "Username: admin"
echo "Password: $AWX_ADMIN_PASSWORD"

echo "Script execution complete."
