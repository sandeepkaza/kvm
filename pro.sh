#!/bin/bash

# Set variables
PROMETHEUS_VERSION="2.44.0"
PROMETHEUS_USER="prometheus"
PROMETHEUS_GROUP="prometheus"
PROMETHEUS_DIR="/usr/local/bin"
PROMETHEUS_CONFIG_DIR="/etc/prometheus"
PROMETHEUS_STORAGE_DIR="/var/lib/prometheus"
PROMETHEUS_YML="$PROMETHEUS_CONFIG_DIR/prometheus.yml"
SERVICE_FILE="/etc/systemd/system/prometheus.service"

# Update package list
echo "Updating package list..."
sudo apt update -y

# Install dependencies
echo "Installing dependencies..."
sudo apt install -y wget tar

# Create prometheus user and group
echo "Creating user and group for Prometheus..."
sudo useradd --no-create-home --shell /bin/false $PROMETHEUS_USER
sudo groupadd $PROMETHEUS_GROUP

# Create necessary directories
echo "Creating necessary directories..."
sudo mkdir -p $PROMETHEUS_CONFIG_DIR
sudo mkdir -p $PROMETHEUS_STORAGE_DIR

# Download and extract Prometheus
echo "Downloading Prometheus v$PROMETHEUS_VERSION..."
cd /tmp
wget https://github.com/prometheus/prometheus/releases/download/v$PROMETHEUS_VERSION/prometheus-$PROMETHEUS_VERSION.linux-amd64.tar.gz

echo "Extracting Prometheus files..."
tar -xvzf prometheus-$PROMETHEUS_VERSION.linux-amd64.tar.gz
sudo mv prometheus-$PROMETHEUS_VERSION.linux-amd64/prometheus $PROMETHEUS_DIR/
sudo mv prometheus-$PROMETHEUS_VERSION.linux-amd64/promtool $PROMETHEUS_DIR/

# Clean up downloaded files
echo "Cleaning up..."
rm -rf prometheus-$PROMETHEUS_VERSION.linux-amd64.tar.gz prometheus-$PROMETHEUS_VERSION.linux-amd64

# Set ownership for Prometheus binaries
echo "Setting permissions for Prometheus binaries..."
sudo chown $PROMETHEUS_USER:$PROMETHEUS_GROUP $PROMETHEUS_DIR/prometheus
sudo chown $PROMETHEUS_USER:$PROMETHEUS_GROUP $PROMETHEUS_DIR/promtool

# Create default Prometheus config file
echo "Creating Prometheus configuration file..."
cat <<EOL | sudo tee $PROMETHEUS_YML
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']
EOL

# Set ownership for configuration files
echo "Setting permissions for Prometheus config..."
sudo chown -R $PROMETHEUS_USER:$PROMETHEUS_GROUP $PROMETHEUS_CONFIG_DIR
sudo chown -R $PROMETHEUS_USER:$PROMETHEUS_GROUP $PROMETHEUS_STORAGE_DIR

# Create Prometheus systemd service
echo "Creating Prometheus systemd service..."
cat <<EOL | sudo tee $SERVICE_FILE
[Unit]
Description=Prometheus
Wants=network-online.target
After=network-online.target

[Service]
User=$PROMETHEUS_USER
Group=$PROMETHEUS_GROUP
Type=simple
ExecStart=$PROMETHEUS_DIR/prometheus \
  --config.file=$PROMETHEUS_YML \
  --storage.tsdb.path=$PROMETHEUS_STORAGE_DIR/ \
  --web.console.templates=$PROMETHEUS_CONFIG_DIR/consoles \
  --web.console.libraries=$PROMETHEUS_CONFIG_DIR/console_libraries

[Install]
WantedBy=multi-user.target
EOL

# Reload systemd to apply the new service
echo "Reloading systemd..."
sudo systemctl daemon-reload

# Start and enable Prometheus service
echo "Starting and enabling Prometheus service..."
sudo systemctl start prometheus
sudo systemctl enable prometheus

# Verify Prometheus status
echo "Verifying Prometheus service status..."
sudo systemctl status prometheus

# Print completion message
echo "Prometheus installation completed successfully."
echo "You can access Prometheus at http://<your-server-ip>:9090"
