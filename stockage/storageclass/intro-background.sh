#!/bin/bash
set -e

SENTINEL="/root/.prep-done"
NS="storage"
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

touch "$SENTINEL"
echo "[prep] Environnement prêt."
