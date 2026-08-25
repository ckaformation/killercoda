#!/bin/bash
# ============================================================================
# Préparation silencieuse :
#   - lien symbolique k -> kubectl (controlplane + node01)
#   - retrait du taint control-plane par défaut : le DaemonSet de l'étape 1
#     doit naturellement couvrir les deux nœuds, sans avoir besoin d'une
#     toleration explicite dans son pod template (même raisonnement que
#     les scénarios précédents de ce chapitre)
#   - namespace applicatif "hoth"
#   - le DaemonSet lui-même est laissé à l'élève : c'est l'objet de
#     l'étape 1
# ============================================================================

PREP_CMDS='ln -sf "$(which kubectl)" /usr/local/bin/k'
bash -c "$PREP_CMDS" &
PID_CONTROLPLANE=$!
ssh -o StrictHostKeyChecking=no -o ConnectTimeout=10 -o BatchMode=yes node01 "$PREP_CMDS" &
PID_NODE01=$!
wait "$PID_CONTROLPLANE"
wait "$PID_NODE01"

kubectl taint nodes controlplane node-role.kubernetes.io/control-plane- 2>/dev/null || true

kubectl create namespace hoth

exit 0
