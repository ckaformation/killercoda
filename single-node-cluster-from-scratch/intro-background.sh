#!/bin/bash
# ============================================================================
# Préparation silencieuse des VM avant que l'élève ne commence.
#
# Backend Killercoda : "kubernetes-kubeadm-2nodes" (controlplane + node01),
# livré avec un cluster Kubernetes déjà installé et déjà joint sur les deux
# nœuds, et les paquets kubeadm/kubelet/kubectl déjà installés. Ce script :
#   1. reset l'état kubeadm (kubeadm reset), sur les deux nœuds ;
#   2. désinstalle les paquets kubeadm/kubelet/kubectl, sur les deux nœuds ;
# afin que l'étape 1 du scénario (installer kubeadm/kubelet/kubectl) soit
# réellement nécessaire, sur les deux nœuds. containerd et les prérequis
# systèmes (swap, modules noyau, sysctl) restent en place : ils sont
# forcément déjà corrects, puisque Kubernetes tournait dessus juste avant.
#
# Ce script s'exécute sur "controlplane" (root). La préparation de "node01"
# se fait à distance via SSH sans mot de passe (confirmé fonctionnel sur ce
# backend).
#
# Doc officielle :
#   https://kubernetes.io/docs/reference/setup-tools/kubeadm/kubeadm-reset/
# ============================================================================

PREP_CMDS='
kubeadm reset -f
rm -rf /etc/cni/net.d
rm -rf "$HOME/.kube"
iptables -F 2>/dev/null
iptables -t nat -F 2>/dev/null
iptables -t mangle -F 2>/dev/null
iptables -X 2>/dev/null

apt-mark unhold kubelet kubeadm kubectl 2>/dev/null
apt-get purge -y kubeadm kubelet kubectl
apt-get autoremove -y
rm -f /etc/apt/sources.list.d/kubernetes.list
rm -f /etc/apt/keyrings/kubernetes-apt-keyring.gpg

systemctl restart containerd
'

# --- 1. Préparation du control-plane (exécution locale) ---
bash -c "$PREP_CMDS"

# --- 2. Préparation de node01 (exécution à distance via SSH) ---
ssh -o StrictHostKeyChecking=no -o ConnectTimeout=10 -o BatchMode=yes node01 "$PREP_CMDS"

exit 0
