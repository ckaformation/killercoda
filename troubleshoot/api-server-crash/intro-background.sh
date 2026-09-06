#!/bin/bash
set -e

MANIFEST="/etc/kubernetes/manifests/kube-apiserver.yaml"
BACKUP="/root/kube-apiserver-backup.yaml"

echo "[prep] Sauvegarde du manifest kube-apiserver"
cp "$MANIFEST" "$BACKUP"

echo "[prep] Injection d'un faux argument (--use-the-force=true)"
sed -i '/^\s*- kube-apiserver$/a\    - --use-the-force=true' "$MANIFEST"

echo "[prep] Attente que kubelet détecte le changement et que le conteneur échoue"
sleep 20

echo "[prep] Environnement prêt (kube-apiserver cassé volontairement, backup dans $BACKUP)."
