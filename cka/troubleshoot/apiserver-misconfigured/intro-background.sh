#!/bin/bash
set -e

CRICTL_VERSION="v1.36.0"
MANIFEST="/etc/kubernetes/manifests/kube-apiserver.yaml"
BACKUP="/root/kube-apiserver-backup.yaml"
STAGING="/tmp/kube-apiserver-staging.yaml"

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

echo "[prep] Sauvegarde du manifest sain"
cp "$MANIFEST" "$BACKUP"

echo "[prep] Retrait temporaire du manifest (force kubelet à arrêter le pod avant de le recréer cassé)"
mv "$MANIFEST" "$STAGING"
sleep 5

echo "[prep] Erreur 1/3 : corruption YAML (metadata: -> metadata;)"
sed -i 's/^metadata:$/metadata;/' "$STAGING"

echo "[prep] Erreur 2/3 : argument inconnu (--midichlorians=9000)"
sed -i '/^\s*- kube-apiserver$/a\    - --midichlorians=9000' "$STAGING"

echo "[prep] Erreur 3/3 : --tls-cert-file pointe vers un fichier inexistant"
sed -i 's#--tls-cert-file=.*#--tls-cert-file=/etc/kubernetes/pki/apiserver-WRONG.crt#' "$STAGING"

echo "[prep] Remise en place du manifest (désormais cassé)"
mv "$STAGING" "$MANIFEST"

echo "[prep] Attente de la réaction de kubelet"
sleep 15

echo "[prep] Environnement prêt (kube-apiserver cassé volontairement, 3 erreurs, backup dans $BACKUP)."
