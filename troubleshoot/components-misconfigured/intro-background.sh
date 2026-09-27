#!/bin/bash
set -e

CRICTL_VERSION="v1.36.0"

echo "[prep] Installation de crictl (${CRICTL_VERSION})"
curl -L "https://github.com/kubernetes-sigs/cri-tools/releases/download/${CRICTL_VERSION}/crictl-${CRICTL_VERSION}-linux-amd64.tar.gz" --output /tmp/crictl.tar.gz
tar zxvf /tmp/crictl.tar.gz -C /usr/local/bin
rm -f /tmp/crictl.tar.gz

echo "[prep] Configuration de crictl (endpoint containerd)"
cat > /etc/crictl.yaml <<'EOF'
runtime-endpoint: unix:///run/containerd/containerd.sock
image-endpoint: unix:///run/containerd/containerd.sock
timeout: 10
EOF

cat > /root/wait-for-ready.sh <<'EOS'
#!/bin/bash
echo "Préparation de l'environnement en cours..."
for i in $(seq 1 40); do
  CM_RUNNING=$(crictl ps --name kube-controller-manager -q 2>/dev/null | head -n1)

  if [ -z "$CM_RUNNING" ]; then
    echo "Environnement prêt."
    exit 0
  fi
  sleep 5
done
echo "L'environnement met plus de temps que prévu à se préparer."
echo "Relance ce script dans quelques instants : ./wait-for-ready.sh"
exit 1
EOS
chmod +x /root/wait-for-ready.sh

echo "[prep] Injection d'un flag inconnu dans le manifest kube-controller-manager (controlplane)"
sed -i '/^\s*- kube-controller-manager$/a\    - --use-the-force=true' /etc/kubernetes/manifests/kube-controller-manager.yaml

echo "[prep] Injection des erreurs kubelet sur node01 (via SSH)"
cat > /tmp/break-kubelet-node01.sh << 'REMOTE_EOF'
#!/bin/bash
sed -i 's/"$/ --use-the-force=true"/' /var/lib/kubelet/kubeadm-flags.env
sed -i 's/^apiVersion:/#apiVersion:/' /var/lib/kubelet/config.yaml
systemctl restart kubelet
REMOTE_EOF

scp -o StrictHostKeyChecking=no /tmp/break-kubelet-node01.sh node01:/tmp/break-kubelet.sh
ssh -o StrictHostKeyChecking=no node01 "chmod +x /tmp/break-kubelet.sh && /tmp/break-kubelet.sh"
rm -f /tmp/break-kubelet-node01.sh

echo "[prep] Attente de la réaction des composants"
sleep 15

echo "[prep] Environnement prêt (kube-controller-manager et kubelet/node01 cassés volontairement)."
