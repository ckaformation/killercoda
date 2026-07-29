#!/bin/bash
# ============================================================================
# Préparation silencieuse des VM avant que l'élève ne commence.
#
# Backend Killercoda : "kubernetes-kubeadm-2nodes" (controlplane + node01),
# livré avec un cluster Kubernetes déjà installé et déjà joint sur les deux
# nœuds. On remet ce cluster à zéro avec "kubeadm reset" (commande officielle
# faite pour ça) pour repartir d'une base "quasi vierge" : containerd, les
# paquets kubeadm/kubelet/kubectl et les prérequis systèmes restent en place
# (ils sont forcément déjà corrects, puisque Kubernetes tournait dessus),
# seul l'état créé par kubeadm est retiré.
#
# Doc officielle :
#   https://kubernetes.io/docs/reference/setup-tools/kubeadm/kubeadm-reset/
#
# ATTENTION : ce script ne s'exécute que sur "controlplane". La remise à zéro
# de "node01" est tentée via SSH depuis ce script. Si le SSH root sans mot de
# passe n'est pas préconfiguré entre les deux hôtes sur ce backend, cette
# partie échoue proprement (sans bloquer le reste du scénario) et l'élève
# devra alors lancer lui-même "sudo kubeadm reset -f" sur l'onglet node01
# (voir la remarque prévue à cet effet dans step1.md).
# ============================================================================

reset_local_node() {
  kubeadm reset -f
  rm -rf /etc/cni/net.d
  rm -rf "$HOME/.kube"
  iptables -F 2>/dev/null
  iptables -t nat -F 2>/dev/null
  iptables -t mangle -F 2>/dev/null
  iptables -X 2>/dev/null
  systemctl restart containerd
}

reset_remote_node() {
  local target="$1"
  ssh -o StrictHostKeyChecking=no -o ConnectTimeout=5 -o BatchMode=yes "$target" '
    kubeadm reset -f
    rm -rf /etc/cni/net.d
    rm -rf "$HOME/.kube"
    iptables -F 2>/dev/null
    iptables -t nat -F 2>/dev/null
    iptables -t mangle -F 2>/dev/null
    iptables -X 2>/dev/null
    systemctl restart containerd
  '
}

# --- 1. Reset du control-plane (exécution locale) ---
reset_local_node

# --- 2. Tentative de reset de node01 via SSH (nom d'hôte, puis IP fixe en secours) ---
if reset_remote_node node01; then
  echo "node01 réinitialisé avec succès via SSH (par nom d'hôte)."
elif reset_remote_node 172.30.2.2; then
  echo "node01 réinitialisé avec succès via SSH (par IP)."
else
  echo "AVERTISSEMENT : impossible de joindre node01 en SSH depuis ce script."
  echo "L'élève devra lancer 'sudo kubeadm reset -f' lui-même sur l'onglet node01."
fi

exit 0
