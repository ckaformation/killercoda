#!/bin/bash
set -e

NS="kamino"

echo "[prep] Création du namespace $NS"
kubectl create namespace "$NS" --dry-run=client -o yaml | kubectl apply -f -

echo "[prep] Vérification que la StorageClass local-path est disponible (déjà installée par défaut sur cette image)"
for i in $(seq 1 24); do
  if kubectl get storageclass local-path >/dev/null 2>&1; then
    break
  fi
  sleep 5
done
if ! kubectl get storageclass local-path >/dev/null 2>&1; then
  echo "[prep] ⚠️  StorageClass local-path introuvable après attente — vérifier si local-path-provisioner est bien préinstallé sur cette image"
  exit 1
fi

echo "[prep] Création du StatefulSet clone-vat (namespace $NS)"
kubectl apply -n "$NS" -f - <<'EOF'
apiVersion: v1
kind: Service
metadata:
  name: clone-vat
spec:
  clusterIP: None
  selector:
    app: clone-vat
  ports:
  - port: 80
---
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: clone-vat
spec:
  serviceName: clone-vat
  replicas: 1
  selector:
    matchLabels:
      app: clone-vat
  template:
    metadata:
      labels:
        app: clone-vat
    spec:
      containers:
      - name: clone-vat
        image: busybox:1.36
        command: ["sh", "-c", "while true; do echo alive >> /data/log.txt; sleep 30; done"]
        volumeMounts:
        - name: data
          mountPath: /data
  volumeClaimTemplates:
  - metadata:
      name: data
    spec:
      accessModes: ["ReadWriteOnce"]
      storageClassName: local-path
      resources:
        requests:
          storage: 1Gi
EOF

echo "[prep] Attente que le pod clone-vat-0 soit Running (sur node01)"
kubectl -n "$NS" wait --for=condition=Ready pod/clone-vat-0 --timeout=120s

echo "[prep] Environnement prêt (clone-vat-0 tourne sur node01)."
