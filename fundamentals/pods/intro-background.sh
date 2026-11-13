#!/bin/bash
# ============================================================================
# Preparation silencieuse (backend kubernetes-kubeadm-2nodes) :
#   - lien symbolique k -> kubectl sur controlplane (l'eleve n'utilise k que
#     sur controlplane ; sur node01 il n'utilise que crictl).
#   - taint node-role.kubernetes.io/control-plane:NoSchedule sur controlplane :
#     le backend l'applique normalement par defaut (le scenario
#     taints-tolerations devait le retirer explicitement pour sa demonstration),
#     mais on le (re)pose avec --overwrite pour ne pas faire reposer l'etape 2
#     sur une hypothese non verifiee. Si le taint est deja la, la commande est
#     sans effet.
#   - crictl sur node01 : installe de facon defensive uniquement s'il est
#     absent (meme principe que dans le scenario static-pods), puis
#     /etc/crictl.yaml pointe vers containerd. Version v1.36.0 (celle que tu as
#     indiquee pour ce cours).
#   - nettoyage de deux fichiers repères de l'eleve sur node01
#     (/root/bb-8-container-id et /root/bb-8-new-container-id) au cas ou une
#     session precedente en aurait laisse.
#   - la connexion ssh en arriere-plan avec StrictHostKeyChecking=no enregistre
#     aussi l'empreinte de node01 dans known_hosts : l'eleve ne devrait pas
#     avoir de question de confirmation en faisant "ssh node01".
# ============================================================================

ln -sf "$(which kubectl)" /usr/local/bin/k

kubectl taint nodes controlplane node-role.kubernetes.io/control-plane:NoSchedule --overwrite >/dev/null 2>&1 || true

NODE01_CMDS='
rm -f /root/bb-8-container-id /root/bb-8-new-container-id

if ! command -v crictl >/dev/null 2>&1; then
  CRICTL_VERSION="v1.36.0"
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

ssh -o StrictHostKeyChecking=no -o ConnectTimeout=10 -o BatchMode=yes node01 "$NODE01_CMDS"

exit 0
