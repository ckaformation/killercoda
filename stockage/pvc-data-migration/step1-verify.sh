#!/bin/bash
NS="hoth"

PVC_NAME=$(kubectl get pvc -n "$NS" -o jsonpath='{range .items[?(@.spec.storageClassName=="retain-storage")]}{.metadata.name}{" "}{end}' | awk '{print $1}')
if [ -z "$PVC_NAME" ]; then
  echo "❌ Aucun PVC avec storageClassName retain-storage trouvé dans $NS"
  exit 1
fi
echo "✅ PVC trouvé : $PVC_NAME"

SIZE=$(kubectl get pvc "$PVC_NAME" -n "$NS" -o jsonpath='{.spec.resources.requests.storage}')
if [ "$SIZE" != "1Gi" ]; then
  echo "❌ Taille attendue 1Gi, trouvée '$SIZE'"
  exit 1
fi
echo "✅ Taille correcte (1Gi)"

ACCESS_MODE=$(kubectl get pvc "$PVC_NAME" -n "$NS" -o jsonpath='{.spec.accessModes[0]}')
if [ "$ACCESS_MODE" != "ReadWriteOnce" ]; then
  echo "❌ AccessMode attendu ReadWriteOnce, trouvé '$ACCESS_MODE'"
  exit 1
fi
echo "✅ AccessMode correct (ReadWriteOnce)"

exit 0
