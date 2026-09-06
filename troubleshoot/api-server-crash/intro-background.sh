#!/bin/bash
set -e

CRICTL_VERSION="v1.37.0"

echo "[prep] Installation de crictl (${CRICTL_VERSION})"
curl -L "https://github.com/kubernetes-sigs/cri-tools/releases/download/${CRICTL_VERSION}/crictl-${CRICTL_VERSION}-linux-amd64.tar.gz" --output /tmp/crictl.tar.gz
tar zxvf /tmp/crictl.tar.gz -C /usr/local/bin
rm -f /tmp/crictl.tar.gz

echo "[prep] Configuration de crictl (endpoint containerd)"
cat > /etc/crictl.yaml <<'EOF'
runtime-endpoint: unix:///run/containerd/containerd.sock
image-endpoint: unix:///run/containerd/containerd.sock
timeout: 10
EOF

echo "[prep] Vérification de crictl"
crictl --version

echo "[prep] Environnement prêt (base saine, aucune panne introduite)."
