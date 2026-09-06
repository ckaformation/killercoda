#!/bin/bash
set -e

SENTINEL="/root/.prep-done"
NS="kamino"
PROVISIONER_VERSION="v0.0.37"

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

echo "[prep] Installation de rancher/local-path-provisioner (${PROVISIONER_VERSION})"
kubectl apply -f "https://raw.githubusercontent.com/rancher/local-path-provisioner/${PROVISIONER_VERSION}/deploy/local-path-storage.yaml"

echo "[prep] Attente du rollout du provisioner"
kubectl -n local-path-storage rollout status deployment/local-path-provisioner --timeout=120s

echo "[prep] Marquage de la StorageClass local-path comme StorageClass par défaut"
kubectl patch storageclass local-path -p '{"metadata":{"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'

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

touch "$SENTINEL"
echo "[prep] Environnement prêt (clone-vat-0 tourne sur node01)."
