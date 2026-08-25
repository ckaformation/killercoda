#!/bin/bash
# ============================================================================
# Préparation silencieuse :
#   - lien symbolique k -> kubectl (controlplane + node01)
#   - retrait du taint control-plane par défaut : à l'étape 2, "luke" doit
#     pouvoir suivre "yoda" jusque sur controlplane via le scheduler normal
#     (contrairement à "yoda", placé par nodeName, qui court-circuite les
#     vérifications de taint) — même raisonnement que dans les scénarios
#     node-selector-scheduling et taints-tolerations.
#   - pod "yoda", placé explicitement sur node01 via nodeName
#   - pod "luke", sans contrainte de placement
#   - les deux définitions YAML déposées dans /root/, pour que l'élève
#     puisse les éditer et les réappliquer (spec.affinity et spec.nodeName
#     sont immuables sur un pod déjà créé : on ne pourra pas se contenter
#     d'un kubectl edit, ce sera justement l'objet de l'étape 1)
# ============================================================================

PREP_CMDS='ln -sf "$(which kubectl)" /usr/local/bin/k'
bash -c "$PREP_CMDS" &
PID_CONTROLPLANE=$!
ssh -o StrictHostKeyChecking=no -o ConnectTimeout=10 -o BatchMode=yes node01 "$PREP_CMDS" &
PID_NODE01=$!
wait "$PID_CONTROLPLANE"
wait "$PID_NODE01"

kubectl taint nodes controlplane node-role.kubernetes.io/control-plane- 2>/dev/null || true

cat > /root/yoda.yaml << 'EOF'
apiVersion: v1
kind: Pod
metadata:
  name: yoda
  labels:
    app: yoda
spec:
  nodeName: node01
  containers:
    - name: nginx
      image: nginx:alpine
EOF

cat > /root/luke.yaml << 'EOF'
apiVersion: v1
kind: Pod
metadata:
  name: luke
  labels:
    app: luke
spec:
  containers:
    - name: nginx
      image: nginx:alpine
EOF

kubectl apply -f /root/yoda.yaml
kubectl apply -f /root/luke.yaml

kubectl wait --for=condition=Ready pod/yoda --timeout=60s
kubectl wait --for=condition=Ready pod/luke --timeout=60s

exit 0
