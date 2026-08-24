#!/bin/bash
# ============================================================================
# Préparation silencieuse :
#   - lien symbolique k -> kubectl
#   - crictl : installé et configuré pour parler à containerd, défensivement
#     (cf. static-pods pour le même raisonnement — pas de confirmation
#     certaine que ce backend Killercoda l'inclut par défaut).
# Pas d'autre préparation nécessaire : ce scénario travaille directement
# sur les certificats déjà générés par kubeadm à l'installation du cluster.
# ============================================================================

ln -sf "$(which kubectl)" /usr/local/bin/k

if ! command -v crictl >/dev/null 2>&1; then
  CRICTL_VERSION="v1.33.0"
  curl -fsSL "https://github.com/kubernetes-sigs/cri-tools/releases/download/${CRICTL_VERSION}/crictl-${CRICTL_VERSION}-linux-amd64.tar.gz" -o /tmp/crictl.tar.gz
  tar zxf /tmp/crictl.tar.gz -C /usr/local/bin
  rm -f /tmp/crictl.tar.gz
fi

cat > /etc/crictl.yaml << EOF
runtime-endpoint: unix:///run/containerd/containerd.sock
image-endpoint: unix:///run/containerd/containerd.sock
timeout: 10
debug: false
EOF

exit 0
