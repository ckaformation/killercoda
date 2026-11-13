#!/bin/bash
if ! kubectl wait --for=condition=Ready node --all --timeout=180s >/dev/null 2>&1; then
  echo "Le nœud n'est pas encore Ready. Vérifie : kubectl get pods -n kube-flannel"
  exit 1
fi
echo "Le nœud est Ready : le réseau de pods fonctionne."
exit 0
