#!/bin/bash
# ============================================================================
# Préparation silencieuse :
#   - lien symbolique k -> kubectl
#   - backend "kubernetes-kubeadm-1node" utilisé tel quel (CNI natif Cilium,
#     supporte les NetworkPolicy — cf. netpol-isolation)
#   - namespace "a" (label custom project=alpha), "b", "c", "d"
#   - pods han(a), chewie(b), lando(c), wedge(d, squad=rebel), biggs(d,
#     squad=rebel) — tous sous nginx:alpine avec curl installé au démarrage
#   - NetworkPolicy CASSÉE dans "b" : namespaceSelector référence
#     project=beta au lieu de project=alpha (valeur réellement présente sur
#     le namespace "a") — objet de l'étape 1
#   - NetworkPolicy CASSÉE dans "d" : combine namespaceSelector (ciblant c)
#     et podSelector (squad=empire, valeur erronée) en ET dans le même
#     élément de la liste "from", au lieu de deux éléments séparés en OU —
#     objet de l'étape 2
# ============================================================================

ln -sf "$(which kubectl)" /usr/local/bin/k

cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Namespace
metadata:
  name: a
  labels:
    project: alpha
---
apiVersion: v1
kind: Namespace
metadata:
  name: b
---
apiVersion: v1
kind: Namespace
metadata:
  name: c
---
apiVersion: v1
kind: Namespace
metadata:
  name: d
EOF

cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: han
  namespace: a
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
  namespace: b
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
  namespace: c
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
  namespace: d
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
  namespace: d
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
  name: allow-from-a
  namespace: b
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
  name: allow-c-and-d-internal
  namespace: d
spec:
  podSelector: {}
  policyTypes:
    - Ingress
  ingress:
    - from:
        - namespaceSelector:
            matchLabels:
              kubernetes.io/metadata.name: c
          podSelector:
            matchLabels:
              squad: empire
      ports:
        - protocol: TCP
          port: 80
EOF

kubectl wait --for=condition=Ready pod/han -n a --timeout=120s
kubectl wait --for=condition=Ready pod/chewie -n b --timeout=120s
kubectl wait --for=condition=Ready pod/lando -n c --timeout=120s
kubectl wait --for=condition=Ready pod/wedge -n d --timeout=120s
kubectl wait --for=condition=Ready pod/biggs -n d --timeout=120s

exit 0
