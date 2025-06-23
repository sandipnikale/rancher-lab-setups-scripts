#Note: this is for lab/test
# curl -sS https://raw.githubusercontent.com/sandipnikale/rancher-lab-setups-scripts/refs/heads/main/set-kubeconfig.sh  | bash
#!/bin/bash

# Define the user for ownership (adjust if needed)
USER_HOME="/home/ubuntu"
USER_NAME="ubuntu"

# Create .kube directory
sudo mkdir -p "$USER_HOME/.kube"

# Copy RKE2 kubeconfig
sudo cp /etc/rancher/rke2/rke2.yaml "$USER_HOME/.kube/config"

# Set correct permissions
sudo chmod 777 "$USER_HOME/.kube/config"
sudo chown "$USER_NAME:$USER_NAME" "$USER_HOME/.kube/config"

# Create symlink for kubectl
if [ ! -L /usr/local/bin/kubectl ]; then
    sudo ln -s /var/lib/rancher/rke2/bin/kubectl /usr/local/bin/kubectl
    echo "kubectl symlink created."
else
    echo "kubectl symlink already exists."
fi

echo "Kubeconfig and kubectl setup complete."
