#!/bin/bash
MANIFEST="/etc/kubernetes/manifests/kube-controller-manager.yaml"

if grep -q "use-the-force" "$MANIFEST" 2>/dev/null; then
  echo "❌ Le flag bidon --use-the-force est toujours présent dans le manifest"
  exit 1
fi
echo "✅ Flag bidon retiré du manifest"

CONTAINER_ID=""
for i in $(seq 1 10); do
  CONTAINER_ID=$(crictl ps --name kube-controller-manager -q 2>/dev/null | head -n1)
  if [ -n "$CONTAINER_ID" ]; then
    break
  fi
  sleep 3
done

if [ -z "$CONTAINER_ID" ]; then
  echo "❌ Aucun conteneur kube-controller-manager en cours d'exécution"
  exit 1
fi
echo "✅ Conteneur kube-controller-manager en cours d'exécution"

exit 0
