#!/bin/bash
set -e

SENTINEL="/root/.prep-done"
NS="jedi-archives"

rm -f "$SENTINEL"

cat > /root/wait-for-prep.sh <<'EOS'
#!/bin/bash
SENTINEL="/root/.prep-done"

echo "Préparation de l'environnement en cours..."
for i in $(seq 1 60); do
  if [ -f "$SENTINEL" ]; then
    echo "Environnement prêt."
    exit 0
  fi
  sleep 5
done

echo "L'environnement met plus de temps que prévu à se préparer."
echo "Relance ce script dans quelques instants : ./wait-for-prep.sh"
exit 1
EOS
chmod +x /root/wait-for-prep.sh

echo "[prep] Création du namespace $NS"
kubectl create namespace "$NS" --dry-run=client -o yaml | kubectl apply -f -

echo "[prep] Préparation du répertoire hostPath"
mkdir -p /data/holocron-pv

echo "[prep] Création du PV (ReadOnlyMany) et du PVC (ReadWriteOnce) — incompatibilité volontaire"
kubectl apply -f - <<'EOF'
apiVersion: v1
kind: PersistentVolume
metadata:
  name: holocron-pv
spec:
  capacity:
    storage: 1Gi
  accessModes:
    - ReadOnlyMany
  persistentVolumeReclaimPolicy: Retain
  storageClassName: ""
  hostPath:
    path: /data/holocron-pv
    type: DirectoryOrCreate
EOF

kubectl apply -n "$NS" -f - <<'EOF'
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: holocron-storage
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: ""
  resources:
    requests:
      storage: 1Gi
EOF

touch "$SENTINEL"
echo "[prep] Environnement prêt (PVC volontairement en Pending : accessMode incompatible avec le PV)."
