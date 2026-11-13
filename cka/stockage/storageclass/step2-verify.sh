#!/bin/bash
NS="storage"

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

PVC_STATUS=$(kubectl get pvc "$PVC_NAME" -n "$NS" -o jsonpath='{.status.phase}')
if [ "$PVC_STATUS" != "Bound" ]; then
  echo "❌ Le PVC n'est pas Bound (statut: $PVC_STATUS) — un pod qui le monte a-t-il bien été créé ? (WaitForFirstConsumer)"
  exit 1
fi
echo "✅ PVC Bound"

POD_NAME=""
for p in $(kubectl get pod -n "$NS" -o jsonpath='{.items[*].metadata.name}'); do
  CLAIM=$(kubectl get pod "$p" -n "$NS" -o jsonpath="{.spec.volumes[?(@.persistentVolumeClaim.claimName=='$PVC_NAME')].persistentVolumeClaim.claimName}" 2>/dev/null)
  if [ "$CLAIM" = "$PVC_NAME" ]; then
    POD_NAME="$p"
    break
  fi
done

if [ -z "$POD_NAME" ]; then
  echo "❌ Aucun pod ne monte le PVC $PVC_NAME"
  exit 1
fi
echo "✅ Pod trouvé : $POD_NAME"

MOUNT_PATH=$(kubectl get pod "$POD_NAME" -n "$NS" -o jsonpath="{.spec.containers[0].volumeMounts[?(@.name=='data')].mountPath}" 2>/dev/null)
if [ -z "$MOUNT_PATH" ]; then
  MOUNT_PATH=$(kubectl get pod "$POD_NAME" -n "$NS" -o jsonpath='{.spec.containers[0].volumeMounts[0].mountPath}' 2>/dev/null)
fi
if [ "$MOUNT_PATH" != "/data" ]; then
  echo "❌ Le volume doit être monté sur /data (trouvé: '$MOUNT_PATH')"
  exit 1
fi
echo "✅ Volume monté sur /data"

PV_NAME=$(kubectl get pvc "$PVC_NAME" -n "$NS" -o jsonpath='{.spec.volumeName}')
HOST_PATH=$(kubectl get pv "$PV_NAME" -o jsonpath='{.spec.hostPath.path}' 2>/dev/null)

FOUND=0
if [ -n "$HOST_PATH" ] && [ -f "${HOST_PATH}/test.txt" ]; then
  FOUND=1
elif find /opt/local-path-provisioner -name test.txt 2>/dev/null | grep -q test.txt; then
  FOUND=1
fi

if [ "$FOUND" -ne 1 ]; then
  echo "❌ /data/test.txt introuvable sur le disque sous /opt/local-path-provisioner"
  echo "As-tu bien fait 'kubectl exec ... -- sh -c \"echo ... > /data/test.txt\"' ?"
  exit 1
fi
echo "✅ test.txt retrouvé sur le disque du nœud"

exit 0
