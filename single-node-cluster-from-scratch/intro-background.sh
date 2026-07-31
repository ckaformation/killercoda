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
# Le script nettoie aussi largement toute config APT Kubernetes résiduelle
# (dépôt, clé, épinglage de version) laissée par l'image pré-construite,
# quel que soit son nom de fichier — pas seulement les fichiers utilisés
# dans step1.md. Sans ce nettoyage large, un dépôt ou un pin résiduel
# pointant vers une ancienne version mineure peut faire installer une
# version différente de celle voulue par la suite (observé : 1.35.1 au
# lieu de 1.36.3 sur un nœud).
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

# Nettoyage large de toute config APT Kubernetes residuelle (depot, cle,
# epinglage de version), quel que soit son nom de fichier.
grep -rlE "pkgs\.k8s\.io|kubernetes" /etc/apt/sources.list.d/ 2>/dev/null | xargs -r rm -f
grep -rlE "pkgs\.k8s\.io|kubeadm|kubelet|kubectl" /etc/apt/preferences.d/ 2>/dev/null | xargs -r rm -f
sed -i "/pkgs\.k8s\.io/d" /etc/apt/sources.list 2>/dev/null
rm -f /etc/apt/keyrings/kubernetes*.gpg /usr/share/keyrings/kubernetes*.gpg /etc/apt/trusted.gpg.d/kubernetes*.gpg

apt-get clean
apt-get update

systemctl restart containerd
'

# --- 1. Préparation du control-plane (exécution locale) ---
bash -c "$PREP_CMDS"

# --- 2. Préparation de node01 (exécution à distance via SSH) ---
ssh -o StrictHostKeyChecking=no -o ConnectTimeout=10 -o BatchMode=yes node01 "$PREP_CMDS"

exit 0
