#!/bin/bash
# ============================================================================
# Preparation silencieuse (namespace default) :
#   - lien symbolique k -> kubectl
#   - manifestes /root/dagobah.yaml, /root/x-wing.yaml, /root/jedi-archives.yaml
#     ecrits des le debut : meme definition (nginx:alpine, 1 replica,
#     terminationGracePeriodSeconds: 1), seuls le nom et le label app changent
#   - page web du PVC ecrite sur le noeud : /data/holocron/index.html
#   - attente que l'API et le noeud soient prets
#   - PV holocron-pv (hostPath /data/holocron, 100Mi, RWO, sans StorageClass)
#     et PVC holocron lie a ce PV (volumeName)
#   - application des 3 Deployments et attente de leur disponibilite
# ============================================================================

ln -sf "$(which kubectl)" /usr/local/bin/k

for D in dagobah x-wing jedi-archives; do
  cat > "/root/$D.yaml" <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: $D
  labels:
    app: $D
spec:
  replicas: 1
  selector:
    matchLabels:
      app: $D
  template:
    metadata:
      labels:
        app: $D
    spec:
      terminationGracePeriodSeconds: 1
      containers:
      - name: nginx
        image: nginx:alpine
EOF
done

mkdir -p /data/holocron
cat > /data/holocron/index.html <<'EOF'
<html><body><h1>Archives Jedi</h1><p>Cette page est stockee sur le PVC holocron.</p></body></html>
EOF
chmod 755 /data/holocron
chmod 644 /data/holocron/index.html

for i in $(seq 1 60); do
  kubectl get nodes >/dev/null 2>&1 && break
  sleep 2
done
kubectl wait --for=condition=Ready node --all --timeout=120s >/dev/null 2>&1 || true

kubectl apply -f - >/dev/null <<'MANIFESTS'
apiVersion: v1
kind: PersistentVolume
metadata:
  name: holocron-pv
spec:
  capacity:
    storage: 100Mi
  accessModes:
  - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  storageClassName: ""
  hostPath:
    path: /data/holocron
    type: DirectoryOrCreate
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: holocron
  namespace: default
spec:
  accessModes:
  - ReadWriteOnce
  storageClassName: ""
  volumeName: holocron-pv
  resources:
    requests:
      storage: 100Mi
MANIFESTS

for D in dagobah x-wing jedi-archives; do
  kubectl apply -f "/root/$D.yaml" >/dev/null 2>&1 || true
done

kubectl wait --for=jsonpath='{.status.phase}'=Bound pvc/holocron --timeout=60s >/dev/null 2>&1 || true
for D in dagobah x-wing jedi-archives; do
  kubectl rollout status "deployment/$D" --timeout=180s >/dev/null 2>&1 || true
done

exit 0
