#!/bin/bash
# ============================================================================
# Préparation silencieuse :
#   - lien symbolique k -> kubectl
#   - namespaces luke, ben, leia
#   - manifestes de l'opérateur déposés dans /root/operator/operator.yaml,
#     PAS appliqués : c'est le travail de l'élève à l'étape 1
#     ("installer l'opérateur"). Le fichier contient tout ce qu'il faut :
#     namespace "operators", ServiceAccount, ClusterRole, un RoleBinding
#     par namespace cible (luke/ben/leia), et le Deployment lui-même.
# ============================================================================

ln -sf "$(which kubectl)" /usr/local/bin/k

kubectl create namespace luke
kubectl create namespace ben
kubectl create namespace leia

mkdir -p /root/operator

cat > /root/operator/operator.yaml << 'EOF'
apiVersion: v1
kind: Namespace
metadata:
  name: operators
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: greeting-operator
  namespace: operators
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: greeting-operator-role
rules:
  - apiGroups: ["training.example.com"]
    resources: ["greetings"]
    verbs: ["get", "list", "watch"]
  - apiGroups: [""]
    resources: ["configmaps"]
    verbs: ["get", "list", "create"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: greeting-operator-luke
  namespace: luke
subjects:
  - kind: ServiceAccount
    name: greeting-operator
    namespace: operators
roleRef:
  kind: ClusterRole
  name: greeting-operator-role
  apiGroup: rbac.authorization.k8s.io
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: greeting-operator-ben
  namespace: ben
subjects:
  - kind: ServiceAccount
    name: greeting-operator
    namespace: operators
roleRef:
  kind: ClusterRole
  name: greeting-operator-role
  apiGroup: rbac.authorization.k8s.io
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: greeting-operator-leia
  namespace: leia
subjects:
  - kind: ServiceAccount
    name: greeting-operator
    namespace: operators
roleRef:
  kind: ClusterRole
  name: greeting-operator-role
  apiGroup: rbac.authorization.k8s.io
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: greeting-operator
  namespace: operators
spec:
  replicas: 1
  selector:
    matchLabels:
      app: greeting-operator
  template:
    metadata:
      labels:
        app: greeting-operator
    spec:
      serviceAccountName: greeting-operator
      containers:
        - name: greeting-operator
          image: bitnami/kubectl:latest
          command:
            - /bin/sh
            - -c
            - |
              echo "Demarrage de l'operateur, namespaces surveilles : luke ben leia"
              while true; do
                for ns in luke ben leia; do
                  for cr in $(kubectl get greetings -n "$ns" -o jsonpath='{.items[*].metadata.name}' 2>/dev/null); do
                    cm_name="${cr}-greeting"
                    if ! kubectl get configmap "$cm_name" -n "$ns" >/dev/null 2>&1; then
                      message=$(kubectl get greeting "$cr" -n "$ns" -o jsonpath='{.spec.message}')
                      kubectl create configmap "$cm_name" -n "$ns" --from-literal=message="$message"
                      echo "ConfigMap $cm_name creee dans $ns pour Greeting/$cr"
                    fi
                  done
                done
                sleep 10
              done
EOF

exit 0
