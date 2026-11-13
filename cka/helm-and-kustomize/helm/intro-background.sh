#!/bin/bash
set -e

if ! command -v helm >/dev/null 2>&1; then
  echo "[prep] Installation de Helm"
  curl -fsSL -o /tmp/get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
  chmod +x /tmp/get_helm.sh
  /tmp/get_helm.sh
  rm -f /tmp/get_helm.sh
fi

echo "[prep] Ajout des dépôts Helm"
helm repo add podinfo https://stefanprodan.github.io/podinfo
helm repo add falcosecurity https://falcosecurity.github.io/charts
helm repo update

echo "[prep] Installation de la release falco (log_level: warning)"
kubectl create namespace falco --dry-run=client -o yaml | kubectl apply -f -
helm install falco falcosecurity/falco \
  --namespace falco \
  --set driver.kind=modern_ebpf \
  --set falco.log_level=warning

echo "[prep] Environnement prêt (falco installé, podinfo à installer par l'élève)."
