#!/bin/bash
command -v kubeadm >/dev/null 2>&1 || { echo "kubeadm introuvable"; exit 1; }
command -v kubelet >/dev/null 2>&1 || { echo "kubelet introuvable"; exit 1; }
command -v kubectl >/dev/null 2>&1 || { echo "kubectl introuvable"; exit 1; }
echo "kubeadm, kubelet et kubectl sont bien installés."
exit 0
