#!/bin/bash

# Install dependencies
echo "Installing dependencies..."
sudo apt-get update
sudo apt-get install -y wget curl unzip

# Step 1: Install Prometheus
PROMETHEUS_VERSION="2.47.0"  # Replace with the desired version of Prometheus
PROMETHEUS_DIR="/usr/local/bin"
PROMETHEUS_BIN="prometheus-$PROMETHEUS_VERSION.linux-amd64"
PROMETHEUS_URL="https://github.com/prometheus/prometheus/releases/download/v$PROMETHEUS_VERSION/prometheus-$PROMETHEUS_VERSION.linux-amd64.tar.gz"

echo "Downloading Prometheus version $PROMETHEUS_VERSION..."
wget $PROMETHEUS_URL -O /tmp/prometheus.tar.gz
tar -xvf /tmp/prometheus.tar.gz -C /tmp

# Move Prometheus binaries to /usr/local/bin
echo "Installing Prometheus binaries..."
sudo mv /tmp/$PROMETHEUS_BIN/prometheus /usr/local/bin/prometheus
sudo mv /tmp/$PROMETHEUS_BIN/promtool /usr/local/bin/promtool
sudo mv /tmp/$PROMETHEUS_BIN/prometheus.yml /etc/prometheus/

# Step 2: Set up Prometheus user and directories
echo "Setting up Prometheus user and directories..."
sudo useradd --no-create-home --shell /bin/false prometheus
sudo mkdir -p /var/lib/prometheus
sudo chown prometheus:prometheus /var/lib/prometheus
sudo chmod 775 /var/lib/prometheus
sudo chown prometheus:prometheus /etc/prometheus/prometheus.yml

# Step 3: Create Prometheus Systemd Service
echo "Creating Prometheus service file..."
sudo bash -c 'cat > /etc/systemd/system/prometheus.service << EOF
[Unit]
Description=Prometheus
After=network.target

[Service]
User=prometheus
Group=prometheus
Type=simple
ExecStart=/usr/local/bin/prometheus \
    --config.file=/etc/prometheus/prometheus.yml \
    --storage.tsdb.path=/var/lib/prometheus/ \
    --web.console.templates=/etc/prometheus/consoles \
    --web.console.libraries=/etc/prometheus/console_libraries
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF'

# Step 4: Modify Prometheus configuration for pikvm scraping
echo "Configuring Prometheus for Pikvm..."
cat <<EOL | sudo tee -a /etc/prometheus/prometheus.yml
scrape_configs:
  - job_name: "pikvm"
    metrics_path: "/api/export/prometheus/metrics"
    basic_auth:
      username: admin
      password: admin
    scheme: https
    static_configs:
      - targets: ["pikvm.local:443"]  # Replace with your pikvm device IP or hostname
    tls_config:
      insecure_skip_verify: true  # Ignore self-signed certs, for production use a proper CA
EOL

# Step 5: Reload systemd, enable and start Prometheus service
echo "Reloading systemd and starting Prometheus..."
sudo systemctl daemon-reload
sudo systemctl enable prometheus
sudo systemctl start prometheus

# Step 6: Verify Prometheus status
echo "Checking Prometheus service status..."
sudo systemctl status prometheus --no-pager

# Step 7: Open Prometheus Web UI (optional, prints the URL)
echo "Prometheus should now be accessible at http://localhost:9090"
