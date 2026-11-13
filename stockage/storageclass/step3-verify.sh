#!/bin/bash
NS="storage"

REMAINING_PVC=$(kubectl get pvc -n "$NS" -o jsonpath='{range .items[?(@.spec.storageClassName=="retain-storage")]}{.metadata.name}{" "}{end}' 2>/dev/null)
if [ -n "$REMAINING_PVC" ]; then
  echo "❌ Un PVC (retain-storage) existe encore dans $NS : $REMAINING_PVC — il devait être supprimé"
  exit 1
fi
echo "✅ Plus aucun PVC retain-storage dans $NS"

REMAINING_POD=$(kubectl get pod -n "$NS" -o jsonpath='{.items[*].metadata.name}' 2>/dev/null)
if echo " $REMAINING_POD " | grep -q ' data-pod '; then
  echo "❌ Le pod data-pod existe encore dans $NS — il devait être supprimé"
  exit 1
fi
echo "✅ Pod supprimé"

PV_NAME=$(kubectl get pv -o jsonpath='{range .items[?(@.spec.storageClassName=="retain-storage")]}{.metadata.name}{" "}{end}' | awk '{print $1}')
if [ -z "$PV_NAME" ]; then
  echo "❌ Aucun PV avec storageClassName retain-storage trouvé — il n'aurait pas dû être supprimé (reclaimPolicy: Retain)"
  exit 1
fi
echo "✅ PV toujours présent : $PV_NAME"

PV_STATUS=$(kubectl get pv "$PV_NAME" -o jsonpath='{.status.phase}')
echo "Statut du PV : $PV_STATUS"
if [ "$PV_STATUS" != "Released" ]; then
  echo "⚠️  Statut attendu 'Released' une fois le PVC supprimé (reclaimPolicy: Retain), trouvé '$PV_STATUS'"
fi

HOST_PATH=$(kubectl get pv "$PV_NAME" -o jsonpath='{.spec.hostPath.path}' 2>/dev/null)

FOUND=0
if [ -n "$HOST_PATH" ] && [ -f "${HOST_PATH}/test.txt" ]; then
  FOUND=1
elif find /opt/local-path-provisioner -name test.txt 2>/dev/null | grep -q test.txt; then
  FOUND=1
fi

if [ "$FOUND" -ne 1 ]; then
  echo "❌ test.txt introuvable sur le disque : les données n'auraient pas dû être supprimées (reclaimPolicy: Retain)"
  exit 1
fi
echo "✅ test.txt toujours présent sur le disque du nœud"

exit 0
