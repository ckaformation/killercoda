#!/bin/bash
# ============================================================================
# Préparation silencieuse :
#   - lien symbolique k -> kubectl
#   - le cluster est entièrement reconstruit (kubeadm reset + réinstallation
#     + kubeadm init + Calico), plutôt que d'utiliser le cluster préinstallé
#     du backend "tel quel" : ce scénario repose intégralement sur
#     l'application réelle des NetworkPolicy, qui dépend du CNI. Sans
#     confirmation du CNI natif de ce backend (et surtout de son support
#     des NetworkPolicy), je préfère garantir Calico explicitement plutôt
#     que risquer un scénario qui ne démontre rien.
#   - namespaces "tatooine" et "alderaan"
#   - pods luke et obi-wan (tatooine), leia (alderaan) : luke et obi-wan
#     tournent tous les deux sous nginx:alpine avec curl installé au
#     démarrage (apk add curl), pour pouvoir servir une page ET lancer des
#     curl — nécessaire à l'étape 3, où on doit tester depuis les deux.
# ============================================================================

echo "Préparation de l'environnement en cours..."

cat > /root/wait-for-prep.sh << 'WAITEOF'
#!/bin/bash
echo "Preparation de l'environnement en cours (reconstruction complete du cluster avec Calico)..."
TIMEOUT=300
ELAPSED=0
while [ ! -f /tmp/.scenario-prep-done ] && [ "$ELAPSED" -lt "$TIMEOUT" ]; do
  sleep 3
  ELAPSED=$((ELAPSED + 3))
done
if [ -f /tmp/.scenario-prep-done ]; then
  echo "C'est pret ! Tu peux continuer."
else
  echo "La preparation prend plus de temps que prevu. Patiente encore un peu avant de continuer."
fi
WAITEOF
chmod +x /root/wait-for-prep.sh

ln -sf "$(which kubectl)" /usr/local/bin/k

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
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.36/deb/Release.key | gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.36/deb/ /" | tee /etc/apt/sources.list.d/kubernetes.list
apt-get update
apt-get install -y kubelet kubeadm kubectl
apt-mark hold kubelet kubeadm kubectl

systemctl restart containerd
'

bash -c "$INSTALL_CMDS"

K8S_VERSION=$(kubeadm version -o short)
kubeadm init \
  --pod-network-cidr=192.168.0.0/16 \
  --kubernetes-version="$K8S_VERSION" \
  --ignore-preflight-errors=NumCPU \
  --ignore-preflight-errors=Mem

mkdir -p /root/.kube
cp -i /etc/kubernetes/admin.conf /root/.kube/config
chown root:root /root/.kube/config
export KUBECONFIG=/root/.kube/config

kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.32.1/manifests/calico.yaml

kubectl wait --for=condition=Ready node --all --timeout=180s

kubectl taint nodes --all node-role.kubernetes.io/control-plane- 2>/dev/null || true

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

touch /tmp/.scenario-prep-done

exit 0
