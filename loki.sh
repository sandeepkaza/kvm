#!/bin/bash

# Define version of Loki to install
LOKI_VERSION="2.8.0"

# Update system
echo "Updating the system..."
sudo apt update -y
sudo apt upgrade -y

# Install required dependencies
echo "Installing dependencies..."
sudo apt install -y wget unzip curl

# Download Loki binary
echo "Downloading Loki v$LOKI_VERSION..."
wget https://github.com/grafana/loki/releases/download/v$LOKI_VERSION/loki-linux-amd64.zip

# Unzip the downloaded Loki binary
echo "Unzipping Loki binary..."
unzip loki-linux-amd64.zip

# Move the Loki binary to /usr/local/bin/
echo "Moving Loki binary to /usr/local/bin/..."
sudo mv loki-linux-amd64 /usr/local/bin/loki

# Make the Loki binary executable
echo "Making Loki binary executable..."
sudo chmod +x /usr/local/bin/loki

# Create configuration directory for Loki
echo "Creating configuration directory..."
sudo mkdir -p /etc/loki

# Create the default Loki config file
echo "Creating Loki configuration file at /etc/loki/local-config.yaml..."
sudo bash -c 'cat > /etc/loki/local-config.yaml << EOF
server:
  http_listen_port: 3100
  grpc_listen_port: 9095
distributor:
  ring:
    kvstore:
      store: inmemory
ingester:
  chunk_idle_period: 5m
  chunk_block_size: 262144
  max_chunk_age: 1h
storage_config:
  boltdb_shipper:
    active_index_directory: /tmp/loki/index
    cache_location: /tmp/loki/cache
    store: filesystem
  filesystem:
    directory: /tmp/loki/chunks
limits_config:
  enforce_metric_name: false
EOF'

# Create systemd service file for Loki
echo "Creating systemd service file for Loki..."
sudo bash -c 'cat > /etc/systemd/system/loki.service << EOF
[Unit]
Description=Loki - Log Aggregation System
After=network.target

[Service]
User=root
ExecStart=/usr/local/bin/loki -config.file=/etc/loki/local-config.yaml
Restart=on-failure
LimitNOFILE=4096

[Install]
WantedBy=multi-user.target
EOF'

# Reload systemd to apply the new service
echo "Reloading systemd..."
sudo systemctl daemon-reload

# Enable and start Loki service
echo "Starting and enabling Loki service..."
sudo systemctl enable loki
sudo systemctl start loki

# Check the status of Loki service
echo "Checking Loki service status..."
sudo systemctl status loki

# Output
echo "Loki has been installed and started successfully. You can access it on port 3100."
echo "To check Loki logs: sudo journalctl -u loki -f"
