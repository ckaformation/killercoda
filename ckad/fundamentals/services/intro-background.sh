#!/bin/bash
# ============================================================================
# Preparation silencieuse (backend kubernetes-kubeadm-2nodes) :
#   - lien symbolique k -> kubectl
#   - taint node-role.kubernetes.io/control-plane:NoSchedule (re)pose avec
#     --overwrite : meme principe que dans pod-fundamentals. Il garantit que
#     les 3 pods d'echo-base sont sur node01 et que controlplane n'en heberge
#     aucun, ce que l'etape 5 (NodePort) met en evidence.
#   - Deployment echo-base : 3 replicas, namespace default, image
#     wbitt/network-multitool (nginx sur le port 80 + curl + outils reseau,
#     d'apres sa page Docker Hub). Sa page d'accueil affiche le nom du
#     conteneur (donc du pod) et son IP.
#   - suppression d'un eventuel /root/pod-ip.txt (fichier repere de l'eleve,
#     etapes 1 et 3).
# ============================================================================

rm -f /root/pod-ip.txt

ln -sf "$(which kubectl)" /usr/local/bin/k

for i in $(seq 1 60); do
  kubectl get nodes >/dev/null 2>&1 && break
  sleep 2
done
kubectl wait --for=condition=Ready node --all --timeout=180s >/dev/null 2>&1 || true

kubectl taint nodes controlplane node-role.kubernetes.io/control-plane:NoSchedule --overwrite >/dev/null 2>&1 || true

cat <<'EOF' | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: echo-base
  namespace: default
spec:
  replicas: 3
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
        image: wbitt/network-multitool
        ports:
        - containerPort: 80
        readinessProbe:
          httpGet:
            path: /
            port: 80
          initialDelaySeconds: 3
          periodSeconds: 3
EOF

kubectl rollout status deployment/echo-base --timeout=180s >/dev/null 2>&1 || true

exit 0
