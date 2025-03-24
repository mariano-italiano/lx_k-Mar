#!/bin/bash

echo "[TASK 1] Install Kernel headers"
dnf install kernel-devel-$(uname -r) >/dev/null 2>&1

echo "[TASK 2] Create module configuration file for containerd"
cat <<EOF | sudo tee /etc/modules-load.d/kubernetes.conf
br_netfilter
ip_vs
ip_vs_rr
ip_vs_wrr
ip_vs_sh
overlay
EOF

# load modules
modprobe ip_vs >/dev/null 2>&1
modprobe ip_vs_rr >/dev/null 2>&1
modprobe ip_vs_wrr >/dev/null 2>&1
modprobe ip_vs_sh >/dev/null 2>&1
modprobe overlay >/dev/null 2>&1
modprobe br_netfilter >/dev/null 2>&1

echo "[TASK 3] Set system configurations for Kubernetes networking"
cat <<EOF | sudo tee /etc/sysctl.d/99-kubernetes-cri.conf
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF

# apply new settings
sysctl --system >/dev/null 2>&1

echo "[TASK 3] Install containerd runtime"
dnf config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo >/dev/null 2>&1
dnf makecache >/dev/null 2>&1
dnf -y install containerd.io >/dev/null 2>&1

echo "[TASK 4] Generate default containerd configuration and save to the newly created default file"
containerd config default | sudo tee /etc/containerd/config.toml >/dev/null 2>&1

echo "[TASK 5] Update containerd option for System Cgroup"
sed -i 's/SystemdCgroup = false/SystemdCgroup = true/g' /etc/containerd/config.toml >/dev/null 2>&1

# apply new settings
systemctl restart containerd >/dev/null 2>&1
systemctl enable --now containerd.service >/dev/null 2>&1

echo "[TASK 6] Disable SWAP"
swapoff -a >/dev/null 2>&1
sed -e '/swap/s/^/#/g' -i /etc/fstab >/dev/null 2>&1

echo "[TASK 7] Configure Firewall"
firewall-cmd --zone=public --permanent --add-port=6443/tcp >/dev/null 2>&1
firewall-cmd --zone=public --permanent --add-port=2379-2380/tcp >/dev/null 2>&1
firewall-cmd --zone=public --permanent --add-port=10250/tcp >/dev/null 2>&1
firewall-cmd --zone=public --permanent --add-port=10251/tcp >/dev/null 2>&1
firewall-cmd --zone=public --permanent --add-port=10252/tcp >/dev/null 2>&1
firewall-cmd --zone=public --permanent --add-port=10255/tcp >/dev/null 2>&1
firewall-cmd --zone=public --permanent --add-port=5473/tcp >/dev/null 2>&1
firewall-cmd --reload >/dev/null 2>&1

echo "[TASK 8] Add K8s repository"
cat <<EOF | sudo tee /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://pkgs.k8s.io/core:/stable:/v1.29/rpm/
enabled=1
gpgcheck=0
EOF

# refresh repo
dnf makecache >/dev/null 2>&1

echo "[TASK 9] Install kubeadm, kubectl, kubelet"
echo
echo "MANUAL STEPS TO FINISH INSTALLATION:"
echo
echo " - To show available versions:                  dnf --showduplicates list available kubeadm"
echo " - To install kubernetes packages:              dnf install -y kubelet kubeadm kubectl"
echo " - To initialize the Kubernetes cluster:        kubeadm init --pod-network-cidr=192.168.0.0/16"
echo " - To set kubelet service to start with boot:   systemctl enable --now kubelet.service"
