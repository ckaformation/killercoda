#!/bin/bash
set -e

NS="hoth"
PROVISIONER_VERSION="v0.0.37"

echo "[prep] Création du namespace $NS"
kubectl create namespace "$NS" --dry-run=client -o yaml | kubectl apply -f -

echo "[prep] Installation de rancher/local-path-provisioner (${PROVISIONER_VERSION})"
kubectl apply -f "https://raw.githubusercontent.com/rancher/local-path-provisioner/${PROVISIONER_VERSION}/deploy/local-path-storage.yaml"

echo "[prep] Attente du rollout du provisioner"
kubectl -n local-path-storage rollout status deployment/local-path-provisioner --timeout=120s

echo "[prep] Marquage de la StorageClass local-path comme StorageClass par défaut"
kubectl patch storageclass local-path -p '{"metadata":{"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'

echo "[prep] Création de la StorageClass retain-storage (copie de local-path, reclaimPolicy: Retain)"
kubectl apply -f - <<'EOF'
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: retain-storage
provisioner: rancher.io/local-path
reclaimPolicy: Retain
volumeBindingMode: WaitForFirstConsumer
EOF

echo "[prep] Création du PVC echo-base-data (storageClassName: local-path)"
kubectl apply -n "$NS" -f - <<'EOF'
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: echo-base-data
spec:
  accessModes:
  - ReadWriteOnce
  storageClassName: local-path
  resources:
    requests:
      storage: 1Gi
EOF

echo "[prep] Création du Deployment echo-base"
kubectl apply -n "$NS" -f - <<'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: echo-base
spec:
  replicas: 1
  selector:
    matchLabels:
      app: echo-base
  template:
    metadata:
      labels:
        app: echo-base
    spec:
      containers:
      - name: echo-base
        image: busybox:1.36
        command: ["sh", "-c", "echo 'Plans de la base Echo' > /data/rebel-plans.txt; sleep 3600"]
        volumeMounts:
        - name: data
          mountPath: /data
      volumes:
      - name: data
        persistentVolumeClaim:
          claimName: echo-base-data
EOF

echo "[prep] Attente que le Deployment echo-base soit prêt"
kubectl -n "$NS" rollout status deployment/echo-base --timeout=120s

echo "[prep] Environnement prêt."
