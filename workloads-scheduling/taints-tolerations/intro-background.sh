#!/bin/bash
# ============================================================================
# Préparation silencieuse :
#   - lien symbolique k -> kubectl (controlplane + node01)
#   - retrait explicite du taint control-plane par défaut : sans ça, les
#     pods seraient déjà bloqués sur controlplane avant même que l'élève
#     n'ajoute ses propres taints, ce qui casserait la démonstration
#     "avant/après" voulue par ce scénario (même raisonnement que dans
#     node-selector-scheduling)
#   - deux Deployments (2 réplicas chacun), SANS toleration : ce sera le
#     travail de l'élève d'en ajouter à millennium-falcon uniquement
# ============================================================================

PREP_CMDS='ln -sf "$(which kubectl)" /usr/local/bin/k'
bash -c "$PREP_CMDS" &
PID_CONTROLPLANE=$!
ssh -o StrictHostKeyChecking=no -o ConnectTimeout=10 -o BatchMode=yes node01 "$PREP_CMDS" &
PID_NODE01=$!
wait "$PID_CONTROLPLANE"
wait "$PID_NODE01"

kubectl taint nodes controlplane node-role.kubernetes.io/control-plane- 2>/dev/null || true

cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: millennium-falcon
spec:
  replicas: 2
  selector:
    matchLabels:
      app: millennium-falcon
  template:
    metadata:
      labels:
        app: millennium-falcon
    spec:
      containers:
        - name: nginx
          image: nginx:alpine
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: x-wing-squadron
spec:
  replicas: 2
  selector:
    matchLabels:
      app: x-wing-squadron
  template:
    metadata:
      labels:
        app: x-wing-squadron
    spec:
      containers:
        - name: nginx
          image: nginx:alpine
EOF

exit 0
