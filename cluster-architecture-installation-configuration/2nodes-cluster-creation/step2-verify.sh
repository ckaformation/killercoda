#!/bin/bash
test -f /etc/kubernetes/admin.conf || { echo "admin.conf introuvable : kubeadm init n'a pas abouti"; exit 1; }
test -f "$HOME/.kube/config" || { echo "kubectl n'est pas configuré (\$HOME/.kube/config manquant)"; exit 1; }
kubectl get nodes >/dev/null 2>&1 || { echo "kubectl ne parvient pas à contacter le cluster"; exit 1; }
echo "Le control-plane a bien été initialisé."
exit 0
