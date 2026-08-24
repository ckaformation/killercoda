#!/bin/bash
# ============================================================================
# Préparation silencieuse :
#   - lien symbolique k -> kubectl (controlplane + node01)
#   - label "side=dark" sur controlplane ET node01 (commun aux deux)
#   - retrait explicite du taint control-plane : ce scénario repose sur la
#     possibilité de scheduler sur les deux nœuds, je ne veux pas dépendre
#     d'un état natif du backend que je ne peux pas garantir avec certitude
#   - deux Deployments (2 réplicas chacun), SANS nodeSelector : ce sera le
#     travail de l'élève de leur en ajouter un, aux étapes 1 et 2
# ============================================================================

PREP_CMDS='ln -sf "$(which kubectl)" /usr/local/bin/k'
bash -c "$PREP_CMDS" &
PID_CONTROLPLANE=$!
ssh -o StrictHostKeyChecking=no -o ConnectTimeout=10 -o BatchMode=yes node01 "$PREP_CMDS" &
PID_NODE01=$!
wait "$PID_CONTROLPLANE"
wait "$PID_NODE01"

kubectl label node controlplane side=dark --overwrite
kubectl label node node01 side=dark --overwrite

kubectl taint nodes controlplane node-role.kubernetes.io/control-plane- 2>/dev/null || true

cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: rebel-fleet
spec:
  replicas: 2
  selector:
    matchLabels:
      app: rebel-fleet
  template:
    metadata:
      labels:
        app: rebel-fleet
    spec:
      containers:
        - name: nginx
          image: nginx:alpine
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: imperial-garrison
spec:
  replicas: 2
  selector:
    matchLabels:
      app: imperial-garrison
  template:
    metadata:
      labels:
        app: imperial-garrison
    spec:
      containers:
        - name: nginx
          image: nginx:alpine
EOF

exit 0
