#!/bin/bash
# ============================================================================
# Préparation silencieuse :
#   - lien symbolique k -> kubectl
#   - Secret "death-star-plans-credentials" (clés username/password)
#   - Deployment "death-star-plans", volontairement cassé : le volume
#     "credentials" est monté sur /tmp dans l'init container, au lieu de
#     /credentials attendu par "cp /credentials/* /config/". Le pod reste
#     donc bloqué en échec d'initialisation tant que l'élève n'a pas
#     corrigé le mountPath (étape 1).
# ============================================================================

ln -sf "$(which kubectl)" /usr/local/bin/k

kubectl create secret generic death-star-plans-credentials \
  --from-literal=username=obi-wan \
  --from-literal=password=1138

cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: death-star-plans
spec:
  replicas: 1
  selector:
    matchLabels:
      app: death-star-plans
  template:
    metadata:
      labels:
        app: death-star-plans
    spec:
      initContainers:
        - name: copy-credentials
          image: busybox
          command: ["sh", "-c", "cp /credentials/* /config/"]
          volumeMounts:
            - name: credentials
              mountPath: /tmp
            - name: config
              mountPath: /config
      containers:
        - name: nginx
          image: nginx:alpine
          volumeMounts:
            - name: config
              mountPath: /config
      volumes:
        - name: credentials
          secret:
            secretName: death-star-plans-credentials
        - name: config
          emptyDir: {}
EOF

exit 0
