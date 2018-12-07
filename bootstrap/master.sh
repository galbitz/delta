apt-get update && apt-get upgrade -y 
apt-get install -y docker.io
echo "deb http://apt.kubernetes.io/ kubernetes-xenial main" >>  /etc/apt/sources.list.d/kubernetes.list
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
apt-get update
apt-get install -y kubeadm=1.12.1-00 kubelet=1.12.1-00 kubectl=1.12.1-00
wget https://tinyurl.com/yb4xturm -O rbac-kdd.yaml
wget https://tinyurl.com/y8lvqc9g -O calico.yaml
kubeadm init \ 
    --pod-network-cidr 192.168.0.0/16 \
    --token "b029ee.968a33e8d8e6bb0d" \
    --token-ttl 0


su albino
mkdir -p $HOME/.kube 
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config 
sudo chown $(id -u):$(id -g) $HOME/.kube/config

sudo cp /root/rbac-kdd.yaml .
kubectl apply -f rbac-kdd.yaml 
sudo cp /root/calico.yaml .
kubectl apply -f calico.yaml 

source <(kubectl completion bash)
echo "source <(kubectl completion bash)" >> ~/.bashrc

exit


