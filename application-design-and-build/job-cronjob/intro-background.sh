#!/bin/bash
# ============================================================================
# Preparation silencieuse :
#   - lien symbolique k -> kubectl
#   - attente que l'API et le noeud soient prets
#   - namespace tatooine
#   - ConfigMap holonet-index (index.html), Deployment holonet (nginx:alpine,
#     ConfigMap monte sous /usr/share/nginx/html) et Service holonet
#   - attente que le Deployment soit disponible
# ============================================================================

ln -sf "$(which kubectl)" /usr/local/bin/k

for i in $(seq 1 60); do
  kubectl get nodes >/dev/null 2>&1 && break
  sleep 2
done
kubectl wait --for=condition=Ready node --all --timeout=120s >/dev/null 2>&1 || true

kubectl get namespace tatooine >/dev/null 2>&1 || kubectl create namespace tatooine >/dev/null 2>&1

kubectl apply -f - >/dev/null <<'MANIFESTS'
apiVersion: v1
kind: ConfigMap
metadata:
  name: holonet-index
  namespace: tatooine
data:
  index.html: |
    <html><body><h1>Holonet - Base Écho</h1><p>Que la Force soit avec ce cluster, padawan !</p></body></html>
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: holonet
  namespace: tatooine
  labels:
    app: holonet
spec:
  replicas: 1
  selector:
    matchLabels:
      app: holonet
  template:
    metadata:
      labels:
        app: holonet
    spec:
      containers:
      - name: nginx
        image: nginx:alpine
        ports:
        - containerPort: 80
        volumeMounts:
        - name: html
          mountPath: /usr/share/nginx/html
      volumes:
      - name: html
        configMap:
          name: holonet-index
---
apiVersion: v1
kind: Service
metadata:
  name: holonet
  namespace: tatooine
spec:
  selector:
    app: holonet
  ports:
  - port: 80
    targetPort: 80
MANIFESTS

kubectl rollout status deployment/holonet -n tatooine --timeout=180s >/dev/null 2>&1 || true

exit 0
