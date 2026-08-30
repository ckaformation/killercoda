#!/bin/bash
# ============================================================================
# Préparation silencieuse :
#   - lien symbolique k -> kubectl
#   - MetalLB (mode L2, manifeste natif officiel v0.16.1), avec un
#     IPAddressPool dont la plage est calculée dynamiquement à partir de
#     l'IP réelle du nœud (mêmes 3 premiers octets, plage .100-.110) —
#     plutôt qu'une plage codée en dur, pour rester valide quel que soit
#     le sous-réseau réellement utilisé par ce backend Killercoda.
#   - metrics-server, avec --kubelet-insecure-tls (nécessaire sur un
#     cluster kubeadm avec certificats auto-signés) : sans lui, le HPA de
#     l'étape 2 resterait indéfiniment à <unknown>, incapable de calculer
#     une utilisation CPU réelle.
#   - Deployment "holonet" (2 réplicas, requests.cpu défini — requis pour
#     qu'un HPA basé sur averageUtilization fonctionne) + Service NodePort
# ============================================================================

ln -sf "$(which kubectl)" /usr/local/bin/k

# --- MetalLB ---
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.16.1/config/manifests/metallb-native.yaml

kubectl wait --namespace metallb-system --for=condition=ready pod --selector=app.kubernetes.io/name=metallb --timeout=180s

NODE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}')
SUBNET=$(echo "$NODE_IP" | cut -d. -f1-3)
RANGE_START="${SUBNET}.100"
RANGE_END="${SUBNET}.110"

cat <<EOF | kubectl apply -f -
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: default-pool
  namespace: metallb-system
spec:
  addresses:
    - ${RANGE_START}-${RANGE_END}
---
apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata:
  name: default-l2
  namespace: metallb-system
spec:
  ipAddressPools:
    - default-pool
EOF

# --- metrics-server ---
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

kubectl patch deployment metrics-server -n kube-system --type='json' \
  -p='[{"op": "add", "path": "/spec/template/spec/containers/0/args/-", "value": "--kubelet-insecure-tls"}]'

kubectl wait --for=condition=Available deployment/metrics-server -n kube-system --timeout=120s

# --- Application ---
cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: holonet
spec:
  replicas: 2
  selector:
    matchLabels:
      app: holonet
  template:
    metadata:
      labels:
        app: holonet
    spec:
      containers:
        - name: nginx
          image: nginx:alpine
          resources:
            requests:
              cpu: 100m
            limits:
              cpu: 200m
---
apiVersion: v1
kind: Service
metadata:
  name: holonet
spec:
  type: NodePort
  selector:
    app: holonet
  ports:
    - port: 80
      targetPort: 80
EOF

kubectl wait --for=condition=Available deployment/holonet --timeout=120s

exit 0
