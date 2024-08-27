#!/bin/bash

# Function to check if Helm is installed
check_helm_installed() {
    if ! command -v helm &> /dev/null; then
        echo "Error: Helm is not installed. Please install Helm to proceed."
        exit 1
    fi
}

# Function to check if a Helm repository is added
check_helm_repo() {
    local repo_name=$1
    if ! helm repo list | grep -q "$repo_name"; then
        return 1
    fi
    return 0
}

# Function to add a Helm repository
add_helm_repo() {
    local repo_name=$1
    local repo_url=$2
    if ! check_helm_repo "$repo_name"; then
        helm repo add "$repo_name" "$repo_url" > /dev/null 2>&1
    fi
}

# Check if Helm is installed
check_helm_installed

# Add the required Helm repositories if they are not already added
add_helm_repo "rancher-latest" "https://releases.rancher.com/server-charts/latest"
add_helm_repo "rancher-stable" "https://releases.rancher.com/server-charts/stable"
add_helm_repo "rancher-prime" "https://charts.rancher.com/server-charts/prime"

# Update all Helm repositories
helm repo update > /dev/null 2>&1

# Get the prime release versions, skipping the header and limiting to 25 rows
prime_versions=$(helm search repo rancher-prime/rancher --versions | awk 'NR>1 {print $1, $2}' | head -n 25 | column -t)

# Get the stable release versions, skipping the header and limiting to 25 rows
stable_versions=$(helm search repo rancher-stable/rancher --versions | awk 'NR>1 {print $1, $2}' | head -n 25 | column -t)

# Get the latest release versions, skipping the header and limiting to 25 rows
latest_versions=$(helm search repo rancher-latest/rancher --versions | awk 'NR>1 {print $1, $2}' | head -n 25 | column -t)

# Print the table for the prime release
echo -e "\nPrime Rancher Releases"
echo -e "-----------------------"
echo -e "NAME                   CHART VERSION"
echo "$prime_versions"
echo -e "-----------------------\n"

# Print the table for the stable release
echo -e "Stable Rancher Releases"
echo -e "-----------------------"
echo -e "NAME                   CHART VERSION"
echo "$stable_versions"
echo -e "-----------------------\n"

# Print the table for the latest release
echo -e "Latest Rancher Releases"
echo -e "-----------------------"
echo -e "NAME                   CHART VERSION"
echo "$latest_versions"
echo -e "-----------------------"
