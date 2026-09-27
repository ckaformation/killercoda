#!/bin/bash
set -e

ROOT="/root/kustomize-multi-region"

echo "[prep] Création des namespaces europe-west1 et us-west1"
kubectl create namespace europe-west1 --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace us-west1 --dry-run=client -o yaml | kubectl apply -f -

echo "[prep] Écriture de la structure Kustomize (base + overlay europe-west1)"
mkdir -p "$ROOT/base" "$ROOT/overlays/europe-west1"

cat > "$ROOT/base/deployment.yaml" <<'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: region-service
spec:
  replicas: 1
  selector:
    matchLabels:
      app: region-service
  template:
    metadata:
      labels:
        app: region-service
    spec:
      containers:
      - name: region-service
        image: busybox:1.36
        command: ["sh", "-c"]
        args:
        - |
          mkdir -p /www
          echo "Region: $REGION" > /www/index.html
          httpd -f -p 8080 -h /www
        env:
        - name: REGION
          valueFrom:
            configMapKeyRef:
              name: region-config
              key: REGION
        ports:
        - containerPort: 8080
EOF

cat > "$ROOT/base/service.yaml" <<'EOF'
apiVersion: v1
kind: Service
metadata:
  name: region-service
spec:
  selector:
    app: region-service
  ports:
  - port: 80
    targetPort: 8080
EOF

cat > "$ROOT/base/configmap.yaml" <<'EOF'
apiVersion: v1
kind: ConfigMap
metadata:
  name: region-config
data:
  REGION: "unspecified"
EOF

cat > "$ROOT/base/kustomization.yaml" <<'EOF'
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
- deployment.yaml
- service.yaml
- configmap.yaml
EOF

cat > "$ROOT/overlays/europe-west1/kustomization.yaml" <<'EOF'
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
namespace: europe-west1
resources:
- ../../base
patches:
- path: configmap-patch.yaml
EOF

cat > "$ROOT/overlays/europe-west1/configmap-patch.yaml" <<'EOF'
apiVersion: v1
kind: ConfigMap
metadata:
  name: region-config
data:
  REGION: "CHANGE_ME"
EOF

echo "[prep] Environnement prêt."
