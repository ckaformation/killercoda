#!/bin/bash
# ============================================================================
# Préparation silencieuse de la VM avant que l'élève ne commence.
# Simule une machine déjà préparée par un administrateur système :
#   - prérequis systèmes (swap, modules noyau, sysctl)
#   - installation et configuration de containerd
#
# Basé sur la documentation officielle Kubernetes :
#   https://kubernetes.io/docs/setup/production-environment/container-runtimes/
#   https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/
# ============================================================================
set -e
export DEBIAN_FRONTEND=noninteractive

# --- 1. Désactivation du swap -------------------------------------------
swapoff -a || true
sed -ri '/\sswap\s/s/^/#/' /etc/fstab || true

# --- 2. Modules noyau requis (overlay, br_netfilter) --------------------
cat <<EOF | tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF
modprobe overlay
modprobe br_netfilter

# --- 3. Paramètres sysctl requis -----------------------------------------
cat <<EOF | tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF
sysctl --system

# --- 4. Installation de containerd ---------------------------------------
apt-get update -y
apt-get install -y containerd

# --- 5. Configuration de containerd : driver de cgroup systemd -----------
# (kubeadm attend le driver "systemd" par défaut depuis Kubernetes v1.22)
mkdir -p /etc/containerd
containerd config default | tee /etc/containerd/config.toml >/dev/null
sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml

systemctl restart containerd
systemctl enable containerd >/dev/null 2>&1 || true

exit 0
