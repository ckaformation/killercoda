#!/bin/bash
if ! kubectl wait --for=condition=Ready pod/yoda --timeout=60s >/dev/null 2>&1; then
  echo "yoda n'est pas encore Ready."
  exit 1
fi
if ! kubectl wait --for=condition=Ready pod/luke --timeout=60s >/dev/null 2>&1; then
  echo "luke n'est pas encore Ready."
  exit 1
fi

YODA_NODE=$(kubectl get pod yoda -o jsonpath='{.spec.nodeName}' 2>/dev/null)
if [ "$YODA_NODE" != "controlplane" ]; then
  echo "yoda devrait maintenant tourner sur controlplane (obtenu: '$YODA_NODE')."
  exit 1
fi

LUKE_NODE=$(kubectl get pod luke -o jsonpath='{.spec.nodeName}' 2>/dev/null)
if [ "$LUKE_NODE" != "controlplane" ]; then
  echo "luke devrait avoir suivi yoda sur controlplane (obtenu: '$LUKE_NODE')."
  exit 1
fi

echo "yoda tourne maintenant sur controlplane, et luke l'a bien suivi grâce à sa pod affinity."
exit 0
