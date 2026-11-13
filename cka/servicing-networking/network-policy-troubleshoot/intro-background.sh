#!/bin/bash
# ============================================================================
# Préparation silencieuse :
#   - lien symbolique k -> kubectl
#   - backend "kubernetes-kubeadm-1node" utilisé tel quel (CNI natif Cilium,
#     supporte les NetworkPolicy — cf. netpol-isolation)
#   - namespaces "dagobah" (label custom project=alpha), "endor", "kamino",
#     "mustafar"
#   - pods han(dagobah), chewie(endor), lando(kamino), wedge(mustafar,
#     squad=rebel), biggs(mustafar, squad=rebel) — tous sous nginx:alpine
#     avec curl installé au démarrage
#   - NetworkPolicy CASSÉE dans "endor" : namespaceSelector référence
#     project=beta au lieu de project=alpha (valeur réellement présente sur
#     le namespace "dagobah") — objet du cas 1
#   - NetworkPolicy CASSÉE dans "mustafar" : combine namespaceSelector
#     (ciblant kamino) et podSelector (squad=rebel, valeur CORRECTE) en ET
#     dans le même élément de la liste "from", au lieu de deux éléments
#     séparés en OU. Seule la syntaxe est fautive ici, pas la valeur du
#     label — objet du cas 2.
# ============================================================================

ln -sf "$(which kubectl)" /usr/local/bin/k

cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Namespace
metadata:
  name: dagobah
  labels:
    project: alpha
---
apiVersion: v1
kind: Namespace
metadata:
  name: endor
---
apiVersion: v1
kind: Namespace
metadata:
  name: kamino
---
apiVersion: v1
kind: Namespace
metadata:
  name: mustafar
EOF

cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: han
  namespace: dagobah
  labels:
    app: han
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
  name: chewie
  namespace: endor
  labels:
    app: chewie
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
  name: lando
  namespace: kamino
  labels:
    app: lando
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
  name: wedge
  namespace: mustafar
  labels:
    app: wedge
    squad: rebel
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
  name: biggs
  namespace: mustafar
  labels:
    app: biggs
    squad: rebel
spec:
  containers:
    - name: web
      image: nginx:alpine
      command:
        - sh
        - -c
        - "apk add --no-cache curl && nginx -g 'daemon off;'"
EOF

cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-from-dagobah
  namespace: endor
spec:
  podSelector: {}
  policyTypes:
    - Ingress
  ingress:
    - from:
        - namespaceSelector:
            matchLabels:
              project: beta
---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-kamino-and-mustafar-internal
  namespace: mustafar
spec:
  podSelector: {}
  policyTypes:
    - Ingress
  ingress:
    - from:
        - namespaceSelector:
            matchLabels:
              kubernetes.io/metadata.name: kamino
          podSelector:
            matchLabels:
              squad: rebel
      ports:
        - protocol: TCP
          port: 80
EOF

kubectl wait --for=condition=Ready pod/han -n dagobah --timeout=120s
kubectl wait --for=condition=Ready pod/chewie -n endor --timeout=120s
kubectl wait --for=condition=Ready pod/lando -n kamino --timeout=120s
kubectl wait --for=condition=Ready pod/wedge -n mustafar --timeout=120s
kubectl wait --for=condition=Ready pod/biggs -n mustafar --timeout=120s

exit 0
