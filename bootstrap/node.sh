apt-get update && apt-get upgrade -y
apt-get install -y docker.io
echo "deb http://apt.kubernetes.io/ kubernetes-xenial main" >>  /etc/apt/sources.list.d/kubernetes.list
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
apt-get update
kubeadm join \ 
    --token b029ee.968a33e8d8e6bb0d \ 
    10.0.0.5:6443 \ 
    --discovery-token-unsafe-skip-ca-verification
