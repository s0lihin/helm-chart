#all node
systemctl stop docker
systemctl stop kubelet
rm -r /root/.kube
rm -r ~/.kube
rm -r /etc/kubernetes
rm -r /usr/libexec/kubernetes
rm -r /var/lib/kubelet
rm -r /var/lib/rancher
rm -r /var/lib/dpkg/info/kube*.*
rm /etc/apt/sources.list.d/kubernetes.list
rm -r /etc/kubernetes/manifests
rm -rf /var/lib/etcd
rm -r /var/log/pods
rm -r /bin/kube*
apt-get remove --allow-change-held-packages -y kubeadm kubelet kubectl
apt-get remove -y etcd
apt-get update
apt-get autoremove --purge
sudo apt-get purge -y docker-engine docker docker.io docker-ce docker-ce-cli
sudo apt-get autoremove -y --purge docker-engine docker docker.io docker-ce
sudo rm -rf /var/lib/docker /etc/docker
sudo rm /etc/apparmor.d/docker
sudo groupdel docker
sudo rm -rf /var/run/docker.sock
