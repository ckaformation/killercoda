#!/bin/bash
# ============================================================================
# Préparation silencieuse : contrairement au scénario "2nodes-cluster-creation"
# (qui repartait de zéro), ici on construit un cluster kubeadm v1.35.x
# COMPLET ET FONCTIONNEL (containerd + kubeadm/kubelet/kubectl + kubeadm init
# + Calico + kubeadm join), pour que l'élève parte d'un cluster "déjà
# installé" à mettre à niveau vers v1.36.x — c'est l'objet de ce scénario.
#
# Basé sur les mêmes commandes officielles que le scénario "from scratch" :
#   https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/
#   https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/create-cluster-kubeadm/
#   https://docs.tigera.io/calico/latest/getting-started/kubernetes/self-managed-onprem/onpremises
#
# Ce script s'exécute sur "controlplane" (root). La préparation de "node01"
# se fait à distance via SSH sans mot de passe (confirmé fonctionnel sur ce
# backend).
# ============================================================================

# --- Dépose du script d'attente utilisé en tête de step1.md ---
cat > /root/wait-for-prep.sh << 'WAITEOF'
#!/bin/bash
echo "Preparation de l'environnement en cours..."
TIMEOUT=240
ELAPSED=0
while [ ! -f /tmp/.scenario-prep-done ] && [ "$ELAPSED" -lt "$TIMEOUT" ]; do
  sleep 2
  ELAPSED=$((ELAPSED + 2))
done
if [ -f /tmp/.scenario-prep-done ]; then
  echo "C'est pret ! Tu peux continuer."
else
  echo "La preparation prend plus de temps que prevu. Patiente encore un peu avant de continuer."
fi
WAITEOF
chmod +x /root/wait-for-prep.sh

# --- Installation de kubeadm/kubelet/kubectl v1.35.x, identique sur les 2 nœuds ---
INSTALL_CMDS='
kubeadm reset -f
rm -rf /etc/cni/net.d
rm -rf "$HOME/.kube"
iptables -F 2>/dev/null
iptables -t nat -F 2>/dev/null
iptables -t mangle -F 2>/dev/null
iptables -X 2>/dev/null

apt-mark unhold kubelet kubeadm kubectl 2>/dev/null
apt-get purge -y kubeadm kubelet kubectl
apt-get autoremove -y
grep -rlE "pkgs\.k8s\.io|kubernetes" /etc/apt/sources.list.d/ 2>/dev/null | xargs -r rm -f
grep -rlE "pkgs\.k8s\.io|kubeadm|kubelet|kubectl" /etc/apt/preferences.d/ 2>/dev/null | xargs -r rm -f
sed -i "/pkgs\.k8s\.io/d" /etc/apt/sources.list 2>/dev/null
rm -f /etc/apt/keyrings/kubernetes*.gpg /usr/share/keyrings/kubernetes*.gpg /etc/apt/trusted.gpg.d/kubernetes*.gpg
apt-get clean

apt-get update
apt-get install -y apt-transport-https ca-certificates curl gpg
mkdir -p -m 755 /etc/apt/keyrings
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.35/deb/Release.key | gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.35/deb/ /" | tee /etc/apt/sources.list.d/kubernetes.list
apt-get update
apt-get install -y kubelet kubeadm kubectl
apt-mark hold kubelet kubeadm kubectl

systemctl restart containerd
'

bash -c "$INSTALL_CMDS" &
PID_CONTROLPLANE=$!
ssh -o StrictHostKeyChecking=no -o ConnectTimeout=10 -o BatchMode=yes node01 "$INSTALL_CMDS" &
PID_NODE01=$!
wait "$PID_CONTROLPLANE"
wait "$PID_NODE01"

# --- Initialiser le control-plane, à la version v1.35.x réellement installée ---
K8S_VERSION=$(kubeadm version -o short)
kubeadm init \
  --pod-network-cidr=192.168.0.0/16 \
  --apiserver-advertise-address=172.30.1.2 \
  --kubernetes-version="$K8S_VERSION" \
  --ignore-preflight-errors=NumCPU \
  --ignore-preflight-errors=Mem

mkdir -p /root/.kube
cp -i /etc/kubernetes/admin.conf /root/.kube/config
chown root:root /root/.kube/config
export KUBECONFIG=/root/.kube/config

# --- Installer Calico (manifeste unique, CIDR par défaut déjà 192.168.0.0/16) ---
kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.32.1/manifests/calico.yaml

# --- Attendre que le control-plane soit Ready avant de joindre node01 ---
kubectl wait --for=condition=Ready node/controlplane --timeout=180s

# --- Joindre node01 ---
JOIN_CMD=$(kubeadm token create --print-join-command)
ssh -o StrictHostKeyChecking=no -o ConnectTimeout=10 -o BatchMode=yes node01 "$JOIN_CMD"

kubectl wait --for=condition=Ready node/node01 --timeout=180s

# --- Fichier témoin : signale que le cluster v1.35.x est prêt ---
touch /tmp/.scenario-prep-done

exit 0
