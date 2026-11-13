#!/bin/bash
# ============================================================================
# Préparation silencieuse :
#   - lien symbolique k -> kubectl
#   - 3 PriorityClass : level1 (100), level2 (1000), level3 (10000)
#   - namespaces "rebellion" et "empire"
#   - rebellion : x-wing-pilot (level1) et rebel-commander (level2)
#   - empire : star-destroyer (level2, memory request 1Gi)
#   - un pod "filler" (namespace default), dont la demande mémoire est
#     CALCULÉE DYNAMIQUEMENT à partir de la mémoire allouable réelle du
#     nœud, pour garantir qu'il ne reste qu'environ 1,5Gi de libre —
#     assez pour que star-destroyer (1Gi) tienne seul, mais pas assez
#     pour qu'un second pod à 1Gi (étape 2) puisse cohabiter avec lui
#     sans préemption. Sans ce calcul, si le nœud dispose de beaucoup de
#     mémoire libre, l'étape 2 ne déclencherait jamais de préemption.
#   - "filler" reçoit priorityClassName: level3 (la même que le pod que
#     l'élève créera à l'étape 2) : il est ainsi totalement protégé de
#     la préemption (qui ne cible que les pods de priorité STRICTEMENT
#     inférieure au pod en attente), garantissant que c'est bien
#     star-destroyer — et lui seul — qui sera préempté à l'étape 2.
# ============================================================================

ln -sf "$(which kubectl)" /usr/local/bin/k

cat <<EOF | kubectl apply -f -
apiVersion: scheduling.k8s.io/v1
kind: PriorityClass
metadata:
  name: level1
value: 100
globalDefault: false
description: "Priorite basse"
---
apiVersion: scheduling.k8s.io/v1
kind: PriorityClass
metadata:
  name: level2
value: 1000
globalDefault: false
description: "Priorite intermediaire"
---
apiVersion: scheduling.k8s.io/v1
kind: PriorityClass
metadata:
  name: level3
value: 10000
globalDefault: false
description: "Priorite haute"
EOF

kubectl create namespace rebellion
kubectl create namespace empire

cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: x-wing-pilot
  namespace: rebellion
spec:
  priorityClassName: level1
  containers:
    - name: nginx
      image: nginx:alpine
---
apiVersion: v1
kind: Pod
metadata:
  name: rebel-commander
  namespace: rebellion
spec:
  priorityClassName: level2
  containers:
    - name: nginx
      image: nginx:alpine
---
apiVersion: v1
kind: Pod
metadata:
  name: star-destroyer
  namespace: empire
spec:
  priorityClassName: level2
  containers:
    - name: nginx
      image: nginx:alpine
      resources:
        requests:
          memory: "1Gi"
EOF

# --- Calcul dynamique de la taille du pod de remplissage ---
NODE=$(kubectl get nodes -o jsonpath='{.items[0].metadata.name}')
ALLOCATABLE_KI=$(kubectl get node "$NODE" -o jsonpath='{.status.allocatable.memory}' | tr -d 'Ki')
ALLOCATABLE_MI=$((ALLOCATABLE_KI / 1024))

SAFETY_MARGIN_MI=300
TARGET_FREE_MI=1536
MIN_ALLOCATABLE_FOR_FILLER_MI=2200

if [ "$ALLOCATABLE_MI" -ge "$MIN_ALLOCATABLE_FOR_FILLER_MI" ]; then
  FILLER_MI=$((ALLOCATABLE_MI - SAFETY_MARGIN_MI - TARGET_FREE_MI))
  if [ "$FILLER_MI" -lt 100 ]; then
    FILLER_MI=100
  fi

  cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: filler
  namespace: default
spec:
  priorityClassName: level3
  containers:
    - name: filler
      image: busybox
      command: ["sleep", "infinity"]
      resources:
        requests:
          memory: "${FILLER_MI}Mi"
EOF

  kubectl wait --for=condition=Ready pod/filler -n default --timeout=60s
fi

kubectl wait --for=condition=Ready pod/x-wing-pilot -n rebellion --timeout=60s
kubectl wait --for=condition=Ready pod/rebel-commander -n rebellion --timeout=60s
kubectl wait --for=condition=Ready pod/star-destroyer -n empire --timeout=60s

exit 0
