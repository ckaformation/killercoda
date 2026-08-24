#!/bin/bash
# ============================================================================
# Préparation silencieuse :
#   - lien symbolique k -> kubectl
#   - namespace "operators"
#   - ServiceAccount + ClusterRole + ClusterRoleBinding de l'opérateur.
#     Le ClusterRole autorise get/list/create sur "namespaces" et
#     get/list/watch sur la future CRD "namespacesets" — SANS le verbe
#     "patch". C'est volontaire : l'étape 4 du scénario consiste
#     justement à l'ajouter, une fois l'opérateur modifié pour labelliser
#     les namespaces qu'il gère.
#   - Le manifeste du StatefulSet (+ son Service headless associé) est
#     déposé dans /root/operator/statefulset.yaml, PAS appliqué : c'est
#     le travail de l'élève à l'étape 1.
# ============================================================================

ln -sf "$(which kubectl)" /usr/local/bin/k

kubectl create namespace operators

kubectl create serviceaccount namespace-operator -n operators

cat <<EOF | kubectl apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: namespace-operator-role
rules:
  - apiGroups: ["training.example.com"]
    resources: ["namespacesets"]
    verbs: ["get", "list", "watch"]
  - apiGroups: [""]
    resources: ["namespaces"]
    verbs: ["get", "list", "create"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: namespace-operator-binding
subjects:
  - kind: ServiceAccount
    name: namespace-operator
    namespace: operators
roleRef:
  kind: ClusterRole
  name: namespace-operator-role
  apiGroup: rbac.authorization.k8s.io
EOF

mkdir -p /root/operator

cat > /root/operator/statefulset.yaml << 'EOF'
apiVersion: v1
kind: Service
metadata:
  name: namespace-operator
  namespace: operators
spec:
  clusterIP: None
  selector:
    app: namespace-operator
  ports:
    - port: 80
---
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: namespace-operator
  namespace: operators
spec:
  serviceName: namespace-operator
  replicas: 1
  selector:
    matchLabels:
      app: namespace-operator
  template:
    metadata:
      labels:
        app: namespace-operator
    spec:
      serviceAccountName: namespace-operator
      containers:
        - name: namespace-operator
          image: bitnami/kubectl:latest
          command:
            - /bin/sh
            - -c
            - |
              echo "Demarrage de l'operateur de namespaces"
              while true; do
                for cr in $(kubectl get namespacesets -o jsonpath='{.items[*].metadata.name}' 2>/dev/null); do
                  for ns in $(kubectl get namespaceset "$cr" -o jsonpath='{.spec.namespaces[*]}' 2>/dev/null); do
                    if ! kubectl get namespace "$ns" >/dev/null 2>&1; then
                      kubectl create namespace "$ns"
                      echo "Namespace $ns cree pour NamespaceSet/$cr"
                    fi
                    # TODO: ajouter ici la commande pour labelliser le namespace
                  done
                done
                sleep 10
              done
EOF

exit 0
