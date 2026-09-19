#!/bin/bash
set -e

NS="kessel-run"

echo "[prep] Installation de metrics-server"
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

echo "[prep] Patch metrics-server (--kubelet-insecure-tls, requis sur kubeadm)"
kubectl -n kube-system patch deployment metrics-server --type='json' \
  -p='[{"op":"add","path":"/spec/template/spec/containers/0/args/-","value":"--kubelet-insecure-tls"}]'

echo "[prep] Attente du rollout de metrics-server"
kubectl -n kube-system rollout status deployment/metrics-server --timeout=120s

echo "[prep] Création du namespace $NS"
kubectl create namespace "$NS" --dry-run=client -o yaml | kubectl apply -f -

echo "[prep] Création du quota (volontairement restrictif, non mentionné à l'élève)"
kubectl apply -n "$NS" -f - <<'EOF'
apiVersion: v1
kind: ResourceQuota
metadata:
  name: kessel-run-quota
spec:
  hard:
    pods: "5"
    limits.cpu: "10"
EOF

echo "[prep] Création du déploiement millennium-falcon"
kubectl apply -n "$NS" -f - <<'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: millennium-falcon
spec:
  replicas: 3
  selector:
    matchLabels:
      app: millennium-falcon
  template:
    metadata:
      labels:
        app: millennium-falcon
    spec:
      containers:
      - name: millennium-falcon
        image: polinux/stress:1.0.4
        command: ["sleep", "infinity"]
        resources:
          requests:
            cpu: 10m
            memory: 16Mi
          limits:
            cpu: 50m
            memory: 32Mi
EOF

echo "[prep] Attente que les 3 pods soient Ready"
kubectl -n "$NS" rollout status deployment/millennium-falcon --timeout=120s

echo "[prep] Attente que metrics-server expose des métriques exploitables"
for i in $(seq 1 20); do
  if kubectl top pod -n "$NS" >/dev/null 2>&1; then
    break
  fi
  sleep 5
done

echo "[prep] Environnement prêt."
