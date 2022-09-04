NODETYPE=$1
MASTERIP=$2
TOKEN=$3
DISCOVERYTOKEN=$4

if [ -z "$MASTERIP" ]; then 
	echo "null"
	MASTERIP=""
fi

errorShowParams()
{
  echo "Invalid Parameters";
  exit;
}

if [ $NODETYPE == "" ];
then
  errorShowParams
fi

if [ $NODETYPE == "master" ] || [ $NODETYPE == "slave" ];
then
  echo "Setting up as "$NODETYPE
else
  errorShowParams
fi

#all node
apt-get update
apt-get install -y curl ca-certificates apt-transport-https gnupg2

#docker
#apt-get install -y docker.io
#docker version
#cat <<EOF > /etc/docker/daemon.json
#{
#    "exec-opts": ["native.cgroupdriver=systemd"]
#}
#EOF
#systemctl restart docker
#systemctl enable docker
#systemctl status docker

#docker with specific version in ubuntu 20.04 with bionic pool
CONTAINERDVERSION=1.4.11-1
DOCKERVERSION=18.09.9
wget -nc https://download.docker.com/linux/ubuntu/dists/bionic/pool/stable/amd64/containerd.io_${CONTAINERDVERSION}_amd64.deb
wget -nc https://download.docker.com/linux/ubuntu/dists/bionic/pool/stable/amd64/docker-ce-cli_${DOCKERVERSION}~3-0~ubuntu-bionic_amd64.deb
wget -nc https://download.docker.com/linux/ubuntu/dists/bionic/pool/stable/amd64/docker-ce_${DOCKERVERSION}~3-0~ubuntu-bionic_amd64.deb

sudo dpkg -i containerd.io_${CONTAINERDVERSION}_amd64.deb
sudo dpkg -i docker-ce-cli_${DOCKERVERSION}~3-0~ubuntu-bionic_amd64.deb
sudo dpkg -i docker-ce_${DOCKERVERSION}~3-0~ubuntu-bionic_amd64.deb

cat <<EOF > /etc/docker/daemon.json
{
    "exec-opts": ["native.cgroupdriver=systemd"],
    "dns": ["8.8.8.8","8.8.4.4"]
}
EOF

sudo systemctl restart docker
usermod -a -G docker root

#kubernetes
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" | tee -a /etc/apt/sources.list.d/kubernetes.list
apt-get update -q
#apt-get install -y kubeadm kubelet kubectl
apt-get install -qy kubelet=1.21.3-00 kubectl=1.21.3-00 kubeadm=1.21.3-00
apt-mark hold kubeadm kubelet kubectl
kubeadm version

# turn off swap
swapoff -a
sed -e '/swap.*/ s/^#*/#/' -i /etc/fstab

#cp ./cert/ca.pem ./cert/kubernetes.pem ./cert/kubernetes-key.pem /etc/etcd
#wget https://github.com/etcd-io/etcd/releases/download/v3.4.13/etcd-v3.4.13-linux-amd64.tar.gz
#tar xvzf etcd-v3.4.13-linux-amd64.tar.gz
#sudo mv etcd-v3.4.13-linux-amd64/etcd* /usr/local/bin/
### master
if [ $NODETYPE == "master" ]; 
then
  echo "Setting up Master"
  ### All master nodes must have etcd
  export RELEASE=$(curl -s https://api.github.com/repos/etcd-io/etcd/releases/latest|grep tag_name | cut -d '"' -f 4)
  wget https://github.com/etcd-io/etcd/releases/download/${RELEASE}/etcd-${RELEASE}-linux-amd64.tar.gz
  tar xvf etcd-${RELEASE}-linux-amd64.tar.gz
  cd etcd-${RELEASE}-linux-amd64
  sudo mv etcd etcdctl etcdutl /usr/bin

  #mkdir /etc/etcd /var/lib/etcd
  #chown etcd:etcd /var/lib/etcd
  #chown etcd:etcd /etc/etcd
  #cp ./cert/ca.pem ./cert/kubernetes.pem ./cert/kubernetes-key.pem /etc/etcd

  if [  -z "$MASTERIP" ];
  then
  	#sudo hostnamectl set-hostname k8-master-node
  	kubeadm init --pod-network-cidr=10.244.0.0/16
  	mkdir -p $HOME/.kube
  	cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
  	chown $(id -u):$(id -g) $HOME/.kube/config
  	kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml
  fi
fi
