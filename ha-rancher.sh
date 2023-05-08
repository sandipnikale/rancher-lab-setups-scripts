#! /bin/bash

main() {

if [[ "${1}" -ne "rke" ]] && [[ "${1}" -ne "rke2" ]] && [[ "${1}" -ne "k3s" ]]
then
    echo "`basename ${1}`: expectedd values are rke, rke2 or k3s "
      exit 1
fi

if [ -e $HOME/.kube ]
then
    echo "File .kube already exists.."
else
    sudo mkdir $HOME/.kube
fi

# Validate passwordless ssh
ssh_valid(){
ssh-keyscan $server1 >> $HOME/.ssh/known_hosts 2>&1 > /dev/null
ssh-keyscan $server2 >> $HOME/.ssh/known_hosts 2>&1 > /dev/null
ssh-keyscan $server3 >> $HOME/.ssh/known_hosts 2>&1 > /dev/null
ssh -i "$ssh" $user@$server2 exit > /dev/null
if [[ "${?}"  -ne 0 ]]
then
    echo "+++++"
    echo ‘ssh failed...please make sure your able able ssh passwordless with provided key’
    echo "+++++"
    exit 1
fi

ssh -i "$ssh" $user@$server3 exit > /dev/null
if [[ "${?}"  -ne 0 ]]
then
    echo "+++++"
    echo ‘ssh failed...please make sure your able able ssh passwordless with provided key’
    echo "+++++"
    exit 1
fi

}
# install rke ha
install_rke(){
echo "$(date +'%F %H:%M:%S') Status: Installing RKE..."
echo "======================================="
cat << EOF >docker.sh
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
curl -sLO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" && sudo chmod +x kubectl && sudo cp kubectl  /usr/local/bin/
EOF
ssh -i "$ssh"  $user@$server2 'bash -s' < docker.sh 2>&1 > /dev/null
ssh -i "$ssh"  $user@$server3 'bash -s' < docker.sh 2>&1 > /dev/null
# get docker for script running host
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
# get kubectl
curl -sLO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" && sudo chmod +x kubectl && sudo cp kubectl  /usr/local/bin/

# get rke binary
wget -q -O rke https://github.com/rancher/rke/releases/download/$rke/rke_linux-amd64
sudo chmod +x rke && sudo mv rke /usr/local/bin 2>&1 > /dev/null
if [ -x "$(command -v rke)" ]; then
    echo "+++++++"
    echo "rke installed successfully..."
else
    echo "please review rke binary"
    exit 1
fi

echo "======================================="


docker="$(sudo find / -name docker.sock)"

cat << EOF >cluster.yml
nodes:
- address: $server1
  port: "22"
  role:
  - controlplane
  - worker
  - etcd
  user: ubuntu
  docker_socket: $docker
  ssh_key_path: $ssh
- address: $server2
  port: "22"
  role:
  - controlplane
  - worker
  - etcd
  user: ubuntu
  docker_socket: $docker
  ssh_key_path: $ssh
- address: $server3
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

rke up --config cluster.yml

if [ -e kube_config_cluster.yml ]
then
    export KUBECONFIG=kube_config_cluster.yml
    echo "Kubeconfig exported plese check kubeclt commands.."
else
    echo "Something went wrong, cannot detect the Kubeconfig file"
fi
echo "======================================="
}

install_rke2(){

echo "$(date +'%F %H:%M:%S') Status: Installing RKE2..."
echo "======================================="
cat << EOF >install.sh
sudo su -c 'mkdir -p /etc/rancher/rke2'
sudo su -c 'touch /etc/rancher/rke2/config.yaml'
EOF
sudo su -c 'chmod +x install.sh'
sudo su -c './install.sh'
ssh -i "$ssh"  $user@$server2 'bash -s' < install.sh 2>&1 > /dev/null
ssh -i "$ssh"  $user@$server3 'bash -s' < install.sh 2>&1 > /dev/null

cat << EOF >config.yaml
server: https://$server1:9345
token: my-shared-secret
EOF
sleep 3
sudo su -c 'echo "token: my-shared-secret" | cat > /etc/rancher/rke2/config.yaml'
cat config.yaml | ssh -i "$ssh" $user@$server2 -T "sudo su -c ' cat > /etc/rancher/rke2/config.yaml'" 2>&1 > /dev/null
cat config.yaml | ssh -i "$ssh" $user@$server3 -T "sudo su -c ' cat > /etc/rancher/rke2/config.yaml'" 2>&1 > /dev/null

#echo "$(date +'%F %H:%M:%S') Status: Installing RKE2..."
cat << EOF >rke2.sh
# Install RKE2  server.
sudo su -c 'curl -sfL https://get.rke2.io | INSTALL_RKE2_VERSION='$INSTALL_RKE2_VERSION' sh - ' 2>&1 > /dev/null
# start and enable for restarts
sudo su -c 'systemctl enable rke2-server.service' 2>&1 > /dev/null
sleep 2
if [[ "${?}"  -ne 0 ]]
then
      exit 1
fi
sudo su -c 'systemctl start rke2-server.service' 2>&1 > /dev/null
sleep 5
if [[ "${?}"  -ne 0 ]]
then
      exit 1
fi
sleep 60
# simlink all the things - kubectl
#sudo su -c 'ln -s '$(sudo find /var/lib/rancher/rke2/data/ -name kubectl)' /usr/local/bin/kubectl' 2>&1 > /dev/null

if [ -e /usr/local/bin/kubectl ]
then
        sudo rm /usr/local/bin/kubectl
else
        echo "ready to install kubectl.."
fi

curl -sLO "https://dl.k8s.io/release/v1.20.15/bin/linux/amd64/kubectl"
sudo chmod +x kubectl && sudo cp kubectl  /usr/local/bin/

# add kubectl conf
sudo su -c 'chmod 644 /etc/rancher/rke2/rke2.yaml' 2>&1 > /dev/null

#sudo cp /etc/rancher/rke2/rke2.yaml $HOME/.kube/ && sudo mv $HOME/.kube/rke2.yaml $HOME/.kube/config

export KUBECONFIG=/etc/rancher/rke2/rke2.yaml 
sudo su -c 'export KUBECONFIG=/etc/rancher/rke2/rke2.yaml'
EOF
sudo su -c 'chmod +x rke2.sh'
echo "$(date +'%F %H:%M:%S') Status: Installing RKE2..."
echo "======================================="
sudo su -c './rke2.sh'
if [[ "${?}"  -ne 0 ]]
then
      echo "rke2 failed to install..."
        exit 1
fi
#export KUBECONFIG=/etc/rancher/rke2/rke2.yaml
ssh -i "$ssh"  $user@$server2 'bash -s' < rke2.sh 2>&1 > /dev/null
ssh -i "$ssh"  $user@$server3 'bash -s' < rke2.sh 2>&1 > /dev/null
if [[ "${?}"  -ne 0 ]]
then
      echo "RKE2 failed to install"
        exit 1
fi
echo "======================================="
}

#install k3s function
install_k3s() {

echo "$(date +'%F %H:%M:%S') Status: Installing K3S..."
echo "======================================="
cat << EOF >install.sh
sudo su -c 'mkdir -p /etc/rancher/k3s'
sudo su -c 'touch /etc/rancher/k3s/config.yaml'
EOF
sudo su -c 'chmod +x install.sh'
sudo su -c './install.sh'
ssh -i "$ssh"  $user@$server2 'bash -s' < install.sh 2>&1 > /dev/null
ssh -i "$ssh"  $user@$server3 'bash -s' < install.sh 2>&1 > /dev/null

cat << EOF >config.yaml
server: https://$server1:9345
token: my-shared-secret
EOF
sleep 3
sudo su -c 'echo "token: my-shared-secret" | cat > /etc/rancher/k3s/config.yaml'
cat config.yaml | ssh -i "$ssh" $user@$server2 -T "sudo su -c ' cat > /etc/rancher/k3s/config.yaml'" 2>&1 > /dev/null
cat config.yaml | ssh -i "$ssh" $user@$server3 -T "sudo su -c ' cat > /etc/rancher/k3s/config.yaml'" 2>&1 > /dev/null


echo "$(date +'%F %H:%M:%S') Status: Installing K3S..."
sudo su -c 'curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION=$k3s sh -s - server --cluster-init'  2>&1 > /dev/null

if [[ "${?}"  -ne 0 ]]
then
      echo "k3s failed to install..."
        exit 1
fi
sudo su -c 'chmod 644 /etc/rancher/k3s/k3s.yaml' 2>&1 > /dev/null
sudo su -c 'export KUBECONFIG=/etc/rancher/k3s/k3s.yaml'
export KUBECONFIG=/etc/rancher/k3s/k3s.yaml

cat << EOF >k3s.sh
sudo su -c 'curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION='$k3s' sh -s - server --server https://$server1:6443' 2>&1 > /dev/null
# add kubectl conf
sudo su -c 'sleep 5'
export KUBECONFIG=/etc/rancher/k3s/k3s.yaml 
sudo su -c 'export KUBECONFIG=/etc/rancher/k3s/k3s.yaml'
#sudo cp /etc/rancher/k3s/k3s.yaml $HOME/.kube/ && sudo mv $HOME/.kube/k3s.yaml $HOME/.kube/config
EOF
sudo su -c 'chmod +x k3s.sh'  > /dev/null

ssh -i "$ssh"  $user@$server2 'bash -s' < k3s.sh 2>&1 > /dev/null
ssh -i "$ssh"  $user@$server3 'bash -s' < k3s.sh 2>&1 > /dev/null

if [[ "${?}"  -ne 0 ]]
then
      echo "k3s failed to install"
      exit 1
fi

echo "$(date +'%F %H:%M:%S') Status: K3S Installed successfully..."
echo "======================================="
}

install_rancher(){
echo "$(date +'%F %H:%M:%S') Status: Installing rancher..."
echo "======================================="
# add helm
sudo curl -#L https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# add needed helm charts
helm repo add rancher-latest https://releases.rancher.com/server-charts/latest
helm repo add jetstack https://charts.jetstack.io


# add the cert-manager CRD
kubectl apply -f https://github.com/jetstack/cert-manager/releases/download/v1.6.1/cert-manager.crds.yaml

# helm install jetstack
helm upgrade -i  cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --version v1.6.1 \
  --set startupapicheck.nodeSelector."kubernetes\.io/os"=linux \
  --create-namespace
  
# helm upgrade -i cert-manager jetstack/cert-manager --namespace cert-manager --create-namespace 2>&1 > /dev/null
# wait till the cert-manager get installed
sleep 30
kubectl wait deployment -n cert-manager cert-manager --for condition=Available=True --timeout=120s
kubectl wait deployment -n cert-manager cert-manager-cainjector --for condition=Available=True --timeout=120s
kubectl wait deployment -n cert-manager cert-manager-webhook --for condition=Available=True --timeout=120s


# helm install rancher
helm upgrade -i rancher rancher-latest/rancher --create-namespace --namespace cattle-system --set hostname=$hostname --set bootstrapPassword=admin@12345 --set replicas=3 --version $rancher 2>&1 > /dev/null

echo "PLEASE DON'T EXIT UNTILL THE SCRIPT ENDS COMPLETLY "

# wait till all rancher pods get spawn
kubectl wait deployment -n cattle-system rancher --for condition=Available=True --timeout=240s 2>&1 > /dev/null
#kubectl wait deployment -n cattle-system rancher-webhook --for condition=Available=True --timeout=240s
echo "######################## "
echo "$(date +'%F %H:%M:%S') Status: Rancher is ready to use! Please visit --> https://$hostname"
echo "######################## "
}

# get all the details from user
server1=`curl -s ifconfig.me.` 2>&1 > /dev/null
echo "The server1/master external IP is: $server1"
echo "Please provide server2 external IP: "
read server2
echo "Please provide server3 external IP: "
read server3
echo "Please provide SSH username: "
read user
echo "Please provide ssh key path: "
read ssh
echo "Please provide the Rancher hostname/FQDN: "
read hostname
echo "Please share the rancher version: "
read rancher

# decide k8s distribution and install
option="${1}"
case ${option} in
        rke) echo "Please provide the RKE version: "
              read rke
              ssh_valid
              install_rke
              install_rancher
              ;;
        rke2) echo "Please provide the RKE2 version: "
              read INSTALL_RKE2_VERSION
              ssh_valid
              install_rke2
              install_rancher
              ;;
        k3s) echo "Please provide the K3S version: "
             read k3s
             ssh_valid
             install_k3s
             install_rancher
             ;;
             *) echo "`basename ${0}`:usage: ['rke2' for rke2 clsuter] ['k3s' for k3s cluster]"
             exit 1 # Command to come out of the program with status 1
             ;;
esac


}
main "$@"



