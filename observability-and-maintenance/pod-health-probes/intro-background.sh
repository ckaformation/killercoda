#!/bin/bash
# ============================================================================
# Preparation silencieuse (courte, pas de wait-for-prep.sh) :
#   - lien symbolique k -> kubectl
#   - /root/echo-base.yaml : manifeste du Deployment echo-base (namespace
#     hoth, 1 replica, nginx:alpine, AUCUNE probe). Il est ecrit avant
#     l'attente de l'API pour etre disponible tout de suite : l'eleve le
#     modifie aux etapes 1 et 2.
#   - au demarrage, le conteneur cree /tmp/life-signs (surveille par la
#     livenessProbe de l'etape 2), ecrit /usr/share/nginx/html/healthz (page
#     /healthz, interrogee par la readinessProbe de l'etape 1), puis lance
#     nginx avec "exec" : nginx devient le PID 1 et recoit directement le
#     SIGTERM du kubelet quand la liveness echoue (etape 3). Sans "exec",
#     le shell PID 1 ne transmettrait pas le signal et l'arret attendrait
#     terminationGracePeriodSeconds (30 s).
#   - namespace hoth + application du manifeste
# ============================================================================

ln -sf "$(which kubectl)" /usr/local/bin/k

cat > /root/echo-base.yaml <<'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: echo-base
  namespace: hoth
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
        image: nginx:alpine
        command:
        - sh
        - -c
        - |
          touch /tmp/life-signs
          echo ok > /usr/share/nginx/html/healthz
          exec nginx -g 'daemon off;'
        ports:
        - containerPort: 80
EOF

# --- Attendre l'API et le noeud ---
for i in $(seq 1 60); do
  kubectl get nodes >/dev/null 2>&1 && break
  sleep 2
done
kubectl wait --for=condition=Ready node --all --timeout=120s >/dev/null 2>&1 || true

# --- Namespace et Deployment ---
kubectl get namespace hoth >/dev/null 2>&1 || kubectl create namespace hoth
kubectl apply -f /root/echo-base.yaml
kubectl -n hoth rollout status deployment/echo-base --timeout=180s >/dev/null 2>&1 || true

exit 0
