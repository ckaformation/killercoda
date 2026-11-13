#!/bin/bash
# ============================================================================
# Préparation silencieuse :
#   - lien symbolique k -> kubectl (cf. rbac-luke-jedi / rbac-cronjob-nettoyeur)
#   - crictl : installé et configuré pour parler à containerd. La plupart
#     des installations kubeadm l'incluent déjà, mais je n'ai pas de
#     confirmation certaine pour ce backend Killercoda précis — installation
#     défensive uniquement si absent, pour ne pas faire reposer tout le
#     scénario sur une hypothèse non vérifiée.
#   - Backend "kubernetes-kubeadm-2nodes" (controlplane + node01) : les
#     manipulations de configuration du kubelet (étape 2) se font sur
#     node01, qui n'héberge aucun composant du control-plane, pour ne
#     prendre aucun risque sur celui-ci. La préparation ci-dessous
#     s'applique donc aux deux nœuds.
# ============================================================================

PREP_CMDS='
ln -sf "$(which kubectl)" /usr/local/bin/k

if ! command -v crictl >/dev/null 2>&1; then
  CRICTL_VERSION="v1.33.0"
  curl -fsSL "https://github.com/kubernetes-sigs/cri-tools/releases/download/${CRICTL_VERSION}/crictl-${CRICTL_VERSION}-linux-amd64.tar.gz" -o /tmp/crictl.tar.gz
  tar zxf /tmp/crictl.tar.gz -C /usr/local/bin
  rm -f /tmp/crictl.tar.gz
fi

cat > /etc/crictl.yaml << EOF
runtime-endpoint: unix:///run/containerd/containerd.sock
image-endpoint: unix:///run/containerd/containerd.sock
timeout: 10
debug: false
EOF
'

bash -c "$PREP_CMDS" &
PID_CONTROLPLANE=$!

ssh -o StrictHostKeyChecking=no -o ConnectTimeout=10 -o BatchMode=yes node01 "$PREP_CMDS" &
PID_NODE01=$!

wait "$PID_CONTROLPLANE"
wait "$PID_NODE01"

exit 0
