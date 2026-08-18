#!/bin/bash
VERSION=$(kubectl get node controlplane -o jsonpath='{.status.nodeInfo.kubeletVersion}' 2>/dev/null)
case "$VERSION" in
  v1.36*) ;;
  *) echo "kubelet sur controlplane n'est pas encore en v1.36.x (version actuelle: $VERSION)"; exit 1 ;;
esac

if ! kubectl wait --for=condition=Ready node/controlplane --timeout=60s >/dev/null 2>&1; then
  echo "Le nœud controlplane n'est pas Ready."
  exit 1
fi

UNSCHEDULABLE=$(kubectl get node controlplane -o jsonpath='{.spec.unschedulable}' 2>/dev/null)
if [ "$UNSCHEDULABLE" = "true" ]; then
  echo "controlplane est encore cordonné : pense à 'kubectl uncordon controlplane'."
  exit 1
fi

echo "controlplane est en v1.36.x, Ready et schedulable."
exit 0
