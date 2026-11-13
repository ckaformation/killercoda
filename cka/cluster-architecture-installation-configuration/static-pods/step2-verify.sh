#!/bin/bash
CURRENT_PATH=$(ssh -o StrictHostKeyChecking=no -o ConnectTimeout=5 -o BatchMode=yes node01 "grep staticPodPath /var/lib/kubelet/config.yaml" 2>/dev/null | awk '{print $2}')
if [ "$CURRENT_PATH" != "/etc/kubernetes/manifests-custom" ]; then
  echo "staticPodPath sur node01 n'est pas encore /etc/kubernetes/manifests-custom (actuel: $CURRENT_PATH)"
  exit 1
fi

if ! kubectl wait --for=condition=Ready node/node01 --timeout=60s >/dev/null 2>&1; then
  echo "node01 n'est pas Ready."
  exit 1
fi

if ! kubectl wait --for=condition=Ready node/controlplane --timeout=60s >/dev/null 2>&1; then
  echo "controlplane n'est pas Ready."
  exit 1
fi

CP_COUNT=$(kubectl get pods -n kube-system -l tier=control-plane --no-headers 2>/dev/null | grep -c Running)
if [ "$CP_COUNT" -lt 4 ]; then
  echo "Il devrait y avoir 4 pods control-plane Running dans kube-system (trouvés: $CP_COUNT) : controlplane n'aurait pas dû être affecté par ce changement."
  exit 1
fi

STATUS=$(kubectl get pod static-web-node01 -o jsonpath='{.status.phase}' 2>/dev/null)
if [ "$STATUS" != "Running" ]; then
  echo "static-web-node01 n'est pas Running (statut: $STATUS)."
  exit 1
fi

CRICTL_CHECK=$(ssh -o StrictHostKeyChecking=no -o ConnectTimeout=5 -o BatchMode=yes node01 "crictl ps --name web -q" 2>/dev/null)
if [ -z "$CRICTL_CHECK" ]; then
  echo "Aucun conteneur nommé 'web' visible via crictl ps sur node01."
  exit 1
fi

echo "staticPodPath a bien été changé sur node01, et tout (control-plane sur controlplane + static-web sur node01) a survécu."
exit 0
