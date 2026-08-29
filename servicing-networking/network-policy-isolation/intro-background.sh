#!/bin/bash
# ============================================================================
# Préparation silencieuse :
#   - lien symbolique k -> kubectl
#   - le backend "kubernetes-kubeadm-1node" est utilisé tel quel, sans reset
#     ni réinstallation : son CNI natif est Cilium, qui implémente les
#     NetworkPolicy standard — pas besoin d'installer Calico ni de
#     reconstruire le cluster pour ce scénario (contrairement à une
#     précédente version de ce script).
#   - namespaces "tatooine" et "alderaan"
#   - pods luke et obi-wan (tatooine), leia (alderaan) : luke et obi-wan
#     tournent tous les deux sous nginx:alpine avec curl installé au
#     démarrage (apk add curl), pour pouvoir servir une page ET lancer des
#     curl — nécessaire à l'étape 3, où on doit tester depuis les deux.
# ============================================================================

ln -sf "$(which kubectl)" /usr/local/bin/k

kubectl create namespace tatooine
kubectl create namespace alderaan

cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: luke
  namespace: tatooine
  labels:
    app: luke
spec:
  containers:
    - name: web
      image: nginx:alpine
      command:
        - sh
        - -c
        - "apk add --no-cache curl && nginx -g 'daemon off;'"
---
apiVersion: v1
kind: Pod
metadata:
  name: obi-wan
  namespace: tatooine
  labels:
    app: obi-wan
spec:
  containers:
    - name: web
      image: nginx:alpine
      command:
        - sh
        - -c
        - "apk add --no-cache curl && nginx -g 'daemon off;'"
---
apiVersion: v1
kind: Pod
metadata:
  name: leia
  namespace: alderaan
  labels:
    app: leia
spec:
  containers:
    - name: web
      image: nginx:alpine
EOF

kubectl wait --for=condition=Ready pod/luke -n tatooine --timeout=120s
kubectl wait --for=condition=Ready pod/obi-wan -n tatooine --timeout=120s
kubectl wait --for=condition=Ready pod/leia -n alderaan --timeout=120s

exit 0
