#!/bin/bash
sudo apt update
sudo apt install -y --no-install-recommends virtualbox
curl -Lo minikube https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64 && chmod +x minikube
sudo curl -Lo /usr/local/bin/kubectl https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl 
sudo chmod +x /usr/local/bin/kubectl
echo "source <(kubectl completion bash)" >> ~/.bashrc
source <(kubectl completion bash)
./minikube start
VBoxManage controlvm "minikube" natpf1 "guestkube,tcp,,30000,,30000"

