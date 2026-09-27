#!/bin/bash
set -e

echo "[prep] Namespace jedi-temple — mauvaise référence de ConfigMap"
kubectl create namespace jedi-temple --dry-run=client -o yaml | kubectl apply -f -
kubectl apply -n jedi-temple -f - <<'EOF'
apiVersion: v1
kind: ConfigMap
metadata:
  name: archive-config
data:
  GREETING: "Bienvenue dans les archives Jedi"
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: archive-terminal
spec:
  replicas: 1
  selector:
    matchLabels:
      app: archive-terminal
  template:
    metadata:
      labels:
        app: archive-terminal
    spec:
      containers:
      - name: archive-terminal
        image: busybox:1.36
        command: ["sh", "-c", "echo $GREETING; sleep 3600"]
        env:
        - name: GREETING
          valueFrom:
            configMapKeyRef:
              name: archive-config-old
              key: GREETING
EOF

echo "[prep] Namespace outer-rim — nodeName inexistant"
kubectl create namespace outer-rim --dry-run=client -o yaml | kubectl apply -f -
kubectl apply -n outer-rim -f - <<'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: long-range-probe
spec:
  replicas: 1
  selector:
    matchLabels:
      app: long-range-probe
  template:
    metadata:
      labels:
        app: long-range-probe
    spec:
      nodeName: probe-station-7
      containers:
      - name: long-range-probe
        image: busybox:1.36
        command: ["sh", "-c", "sleep 3600"]
EOF

echo "[prep] Namespace endor — mauvais serviceAccount"
kubectl create namespace endor --dry-run=client -o yaml | kubectl apply -f -
kubectl apply -n endor -f - <<'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ewok-patrol
spec:
  replicas: 1
  selector:
    matchLabels:
      app: ewok-patrol
  template:
    metadata:
      labels:
        app: ewok-patrol
    spec:
      serviceAccountName: imperial-clearance
      containers:
      - name: ewok-patrol
        image: busybox:1.36
        command: ["sh", "-c", "sleep 3600"]
EOF

echo "[prep] Environnement prêt (3 déploiements volontairement en échec)."
