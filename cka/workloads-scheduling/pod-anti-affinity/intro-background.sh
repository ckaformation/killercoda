#!/bin/bash
# ============================================================================
# Préparation silencieuse :
#   - lien symbolique k -> kubectl (controlplane + node01)
#   - retrait du taint control-plane par défaut : "luke" doit pouvoir se
#     placer sur controlplane via le scheduler normal à l'étape 1 (même
#     raisonnement que dans pod-affinity, node-selector-scheduling et
#     taints-tolerations)
#   - pod "yoda", placé explicitement sur node01 via nodeName, déjà lancé
#   - fichier /root/luke.yaml déposé sur disque, mais PAS appliqué : c'est
#     à l'élève de le compléter (ajout de la pod anti-affinity) puis de le
#     lancer lui-même à l'étape 1 — "luke" n'existe donc pas encore au
#     démarrage du scénario (même pattern que pod-affinity)
#   - /root/yoda.yaml également déposé : servira de base à la copie
#     "yoda-2" à l'étape 2
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

kubectl wait --for=condition=Ready pod/yoda --timeout=60s

exit 0
