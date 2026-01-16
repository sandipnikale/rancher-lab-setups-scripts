#!/bin/bash

# RKE2 Server Installation Script
# Exit on any error
set -e

# Prompt user for configuration
read -p "Enter the SERVER address (e.g., 192.168.1.100 or server.example.com): " SERVER
if [ -z "$SERVER" ]; then
    echo "Error: SERVER address cannot be empty"
    exit 1
fi

read -p "Enter the RKE2 version to install (e.g., v1.24.9+rke2r1): " INSTALL_RKE2_VERSION
if [ -z "$INSTALL_RKE2_VERSION" ]; then
    echo "Error: INSTALL_RKE2_VERSION cannot be empty"
    exit 1
fi

echo "Starting RKE2 installation..."
echo "Server: $SERVER"
echo "RKE2 Version: $INSTALL_RKE2_VERSION"

# Create RKE2 configuration directory
sudo mkdir -p /etc/rancher/rke2

# Create RKE2 configuration file
sudo tee /etc/rancher/rke2/config.yaml > /dev/null <<EOF
server: https://$SERVER:9345
token: my-shared-secret
EOF

echo "Configuration file created successfully"

# Install RKE2 server
echo "Installing RKE2 server..."
#curl -sfL https://get.rke2.io | INSTALL_RKE2_VERSION="$INSTALL_RKE2_VERSION" sudo sh - 2>&1 > /dev/null
sudo su -c 'curl -sfL https://get.rke2.io | INSTALL_RKE2_VERSION='$INSTALL_RKE2_VERSION' sh - ' 2>&1 > /dev/null
# Enable RKE2 service
echo "Enabling RKE2 server service..."
sudo systemctl enable rke2-server.service 2>&1 > /dev/null
sleep 2

# Start RKE2 service
echo "Starting RKE2 server service..."
sudo systemctl start rke2-server.service 2>&1 > /dev/null
sleep 5

# Wait for RKE2 to initialize
echo "Waiting for RKE2 to initialize (30 seconds)..."
sleep 30

# Install kubectl
echo "Installing kubectl..."
if [ -e /usr/local/bin/kubectl ]; then
    echo "Removing existing kubectl..."
    sudo rm /usr/local/bin/kubectl
else
    echo "Ready to install kubectl..."
fi

curl -sLO "https://dl.k8s.io/release/v1.20.15/bin/linux/amd64/kubectl"
sudo chmod +x kubectl
sudo mv kubectl /usr/local/bin/

# Configure kubectl access
# simlink all the things - kubectl
#sudo su -c 'ln -s '$(sudo find /var/lib/rancher/rke2/data/ -name kubectl)' /usr/local/bin/kubectl 2>&1 > /dev/null'

if [ -e /usr/local/bin/kubectl ]
then
        sudo rm /usr/local/bin/kubectl
else
        echo "ready to install kubectl.."
fi

curl -sLO "https://dl.k8s.io/release/v1.20.15/bin/linux/amd64/kubectl"
sudo chmod +x kubectl && sudo cp kubectl  /usr/local/bin/
#wget -q  https://storage.googleapis.com/kubernetes-release/release/v1.23.7/bin/linux/amd64/kubectl && sudo chmod +x kubectl && sudo cp kubectl  /usr/local/bin/

sudo su -c 'chmod 644 /etc/rancher/rke2/rke2.yaml' 2>&1 > /dev/null

# add kubectl conf
sudo cp /etc/rancher/rke2/rke2.yaml $HOME/.kube/ && sudo mv $HOME/.kube/rke2.yaml $HOME/.kube/config
# sudo su -c 'export KUBECONFIG=/etc/rancher/rke2/rke2.yaml'
# export KUBECONFIG=/etc/rancher/rke2/rke2.yaml

echo "RKE2 installation completed successfully!"
echo "Run 'kubectl get nodes' to verify the installation"
