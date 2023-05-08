#! /bin/bash

main() {

if [[ "${1}" -ne "rke" ]] && [[ "${1}" -ne "rke2" ]] && [[ "${1}" -ne "k3s" ]]
then
    echo "`basename ${1}`: expectedd values are rke, rke2 or k3s "
      exit 1
fi

# need to install jq 
YUM_CMD=$(which yum)
APT_GET_CMD=$(which apt-get)
ZYPPER_CMD=$(which zypper)

 if [[ ! -z $YUM_CMD ]]; then
    sudo yum install -y jq 2>&1 > /dev/null
 elif [[ ! -z $APT_GET_CMD ]]; then
    sudo apt-get install -y jq 2>&1 > /dev/null
 elif [[ ! -z $ZYPPER_CMD ]]; then
    sudo zypper install -y jq 2>&1 > /dev/null
 else
    echo "error can't install package jq"
    exit 1;
 fi

echo "Please provide the Rancher host/FQDN: "
read rancher_url

echo "Please provide the bearer token: "
read bearer_token

echo "Please provide downstream cluster name: "
read cluster_name

# create file for stderr & stdout logs.
#if [ -e /tmp/rancher-logs ]
#then
#    echo "File /tmp/rancher-logs already exists.."
#else
#    sudo touch /tmp/rancher-logs
#    sudo chmod 644 /tmp/rancher-logs
#fi

install_rke(){
# Verify docker
echo "Please provide ssh_key_path..."
read ssh

if [ -x "$(command -v docker)" ]; then
        echo "docker is already installed..."
        echo "+++++++"
        sudo usermod -aG docker `whoami` 2>&1 > /dev/null
else
    echo "Installing docker..."
    curl -fsSL https://get.docker.com -o get-docker.sh && sudo chmod +x get-docker.sh && sudo bash get-docker.sh 2>&1 > /dev/null
    sleep 5
    sudo usermod -aG docker `whoami` 2>&1 > /dev/null
fi
echo "======================================="
# verify ssh
#if [ -e ~/.ssh/id_rsa ]
#then
#  echo "file allready exists"
#else
#  ssh-keygen -b 2048 -t rsa -f ~/.ssh/id_rsa -q -N ""
#fi

# get kubectl utility
#wget -q  https://storage.googleapis.com/kubernetes-release/release/v1.23.7/bin/linux/amd64/kubectl && sudo chmod +x kubectl && sudo cp kubectl  /usr/local/bin/
curl -sLO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" && sudo chmod +x kubectl && sudo cp kubectl  /usr/local/bin/
# get rke utility
wget -q -O rke https://github.com/rancher/rke/releases/download/$rke/rke_linux-amd64 2>&1 > /dev/null
sudo chmod +x rke && sudo mv rke /usr/local/bin 2>&1 > /dev/null
if [ -x "$(command -v rke)" ]; then
    echo "+++++++"
    echo "rke installed successfully..."
else
    echo "please review rke binary"
    exit 1
fi
echo "======================================="

ip=`curl -s ifconfig.me.` 2>&1 > /dev/null
ssh-keyscan $ip >> $HOME/.ssh/known_hosts

# validate ssh key
ssh -i "$ssh" `whoami`@$ip exit > /dev/null
if [[ "${?}"  -ne 0 ]]
then
    echo "+++++"
    echo ‘ssh failed...please make sure your able able ssh passwordless with provided key’
    echo "+++++"
    exit 1
fi

docker="$(sudo find / -name docker.sock)"

cat << EOF >cluster.yml
nodes:
- address: $ip
  port: "22"
  role:
  - controlplane
  - worker
  - etcd
  user: ubuntu
  docker_socket: $docker
  ssh_key_path: $ssh
services:
  etcd:
    backup_config:
      interval_hours: 12
      retention: 6
EOF

echo "$(date +'%F %H:%M:%S') Status: Installing RKE..."
echo "++++++++++++++++"
rke up --config cluster.yml

if [ -e kube_config_cluster.yml ]
then
    export KUBECONFIG=kube_config_cluster.yml
    echo "Kubeconfig exported plese check kubeclt commands.."
else
    echo "Something went wrong, cannot detect the Kubeconfig file"
fi

}

install_rke2() {
echo "$(date +'%F %H:%M:%S') Status: Installing RKE2..."
echo "++++++++++++++++"
# Install RKE2  server.
sudo su -c 'curl -sfL https://get.rke2.io | INSTALL_RKE2_VERSION=$INSTALL_RKE2_VERSION sh - ' 2>&1 > /dev/null
# start and enable for restarts
sudo su -c 'systemctl enable rke2-server.service' 2>&1 >  /dev/null
if [[ "${?}"  -ne 0 ]]
then
    echo ‘Service failed to enable’
      exit 1
fi

sudo su -c 'systemctl start rke2-server.service' 2>&1 >  /dev/null
if [[ "${?}"  -ne 0 ]]
then
    echo ‘Service failed to start’
      exit 1
fi

# simlink all the things - kubectl
sudo su -c 'ln -s $(sudo find /var/lib/rancher/rke2/data/ -name kubectl) /usr/local/bin/kubectl 2>&1 > /dev/null'

sudo su -c 'chmod 644 /etc/rancher/rke2/rke2.yaml' 2>&1 > /dev/null

# add kubectl conf
sudo su -c 'export KUBECONFIG=/etc/rancher/rke2/rke2.yaml'
export KUBECONFIG=/etc/rancher/rke2/rke2.yaml
echo "++++++++++++++++"
echo "RKE2 is installed successfully..."
echo "++++++++++++++++"
}

install_k3s() {
echo "$(date +'%F %H:%M:%S') Status: Installing K3S..."
echo "++++++++++++++++"
# Install K3S
sudo su -c 'sudo curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION=$k3s sh - ' 2>&1 > /dev/null

# add kubectl conf
sudo su -c 'chmod 644 /etc/rancher/k3s/k3s.yaml' 2>&1 > /dev/null
sudo su -c 'export KUBECONFIG=/etc/rancher/k3s/k3s.yaml'
export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
echo "++++++++++++++++"
echo "K3S is installed successfully..."
echo "++++++++++++++++"

}

import_cluster() {

if ! command -v "jq" &> /dev/null; then
echo "Missing jq"
exit 1
fi

if ! command -v "kubectl" &> /dev/null; then
echo "Missing kubectl"
exit 1
fi


if [[ -z "${KUBERNETES_SERVICE_HOST}" ]]; then
    echo "Cluster not registered yet.."
else
    if kubectl get namespace cattle-system; then
        echo "Cluster has already been registered"
        exit 0
    fi
fi

# Create cluster and extract cluster ID:
CLUSTER=`curl -ks "https://${rancher_url}/v3/cluster" -H 'content-type: application/json' -H "Authorization: Bearer $bearer_token" --data-binary '{"type":"cluster","name":"'${cluster_name}'","import":true}'`
CLUSTERID=`echo $CLUSTER | jq -r .id`
echo "Cluster ID: ${CLUSTERID}"

# Generate registration token:
ID=`curl -ks "https://${rancher_url}/v3/clusters/${CLUSTERID}/clusterregistrationtoken" -H 'content-type: application/json' -H "Authorization: Bearer $bearer_token" --data-binary '{"type":"clusterRegistrationToken","clusterId":"'$CLUSTERID'"}' | jq -r .id`

sleep 2

# Extract Registration Command:
COMMAND=`curl -ks "https://${rancher_url}/v3/clusters/${CLUSTERID}/clusterregistrationtoken/$ID" -H 'content-type: application/json' -H "Authorization: Bearer $bearer_token" | jq -r .insecureCommand`
echo -p "Insecure Command: \n${COMMAND}"
eval "${COMMAND}"

}

# decide k8s distribution and install
option="${1}"
case ${option} in
        rke) echo "Please provide the RKE version: "
              read rke
              install_rke
              import_cluster
              ;;
        rke2) echo "Please provide the RKE2 version: "
              read INSTALL_RKE2_VERSION
              install_rke2
              import_cluster
              ;;
        k3s) echo "Please provide the K3S version: "
             read k3s
             install_k3s
             import_cluster
             ;;
          *) echo "`basename ${0}`:usage: ['rke2' for rke2 clsuter] ['k3s' for k3s cluster]"
             exit 1 # Command to come out of the program with status 1
             ;;
esac


}

main "$@"

