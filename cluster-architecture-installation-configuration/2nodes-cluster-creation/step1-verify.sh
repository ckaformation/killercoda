#!/bin/bash
command -v kubeadm >/dev/null 2>&1 || { echo "kubeadm introuvable sur controlplane"; exit 1; }
command -v kubelet >/dev/null 2>&1 || { echo "kubelet introuvable sur controlplane"; exit 1; }
command -v kubectl >/dev/null 2>&1 || { echo "kubectl introuvable sur controlplane"; exit 1; }

ssh -o StrictHostKeyChecking=no -o ConnectTimeout=5 -o BatchMode=yes node01 \
  'command -v kubeadm && command -v kubelet && command -v kubectl' >/dev/null 2>&1 \
  || { echo "kubeadm/kubelet/kubectl introuvables sur node01"; exit 1; }

echo "kubeadm, kubelet et kubectl sont bien installés sur controlplane et node01."
exit 0
