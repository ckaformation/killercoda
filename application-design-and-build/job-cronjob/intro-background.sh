#!/bin/bash
# ============================================================================
# Preparation silencieuse :
#   - lien symbolique k -> kubectl
#   - attente que l'API et le noeud soient prets
#   - creation des namespaces hoth et endor
#   - creation de 2 contexts supplementaires (hoth-admin, endor-admin) qui
#     reprennent le cluster et le user du context initial, avec un namespace
#     par defaut different
#   - positionnement sur hoth-admin
# ============================================================================

ln -sf "$(which kubectl)" /usr/local/bin/k

for i in $(seq 1 60); do
  kubectl get nodes >/dev/null 2>&1 && break
  sleep 2
done
kubectl wait --for=condition=Ready node --all --timeout=120s >/dev/null 2>&1 || true

for NS in hoth endor; do
  kubectl get namespace "$NS" >/dev/null 2>&1 || kubectl create namespace "$NS" >/dev/null 2>&1
done

# Cluster et user du context initial (--minify = context courant uniquement)
CLUSTER=$(kubectl config view --minify -o jsonpath='{.contexts[0].context.cluster}' 2>/dev/null)
USER_NAME=$(kubectl config view --minify -o jsonpath='{.contexts[0].context.user}' 2>/dev/null)
# Repli si le kubeconfig n'a pas de context courant
[ -n "$CLUSTER" ] || CLUSTER=$(kubectl config view -o jsonpath='{.clusters[0].name}' 2>/dev/null)
[ -n "$USER_NAME" ] || USER_NAME=$(kubectl config view -o jsonpath='{.users[0].name}' 2>/dev/null)

kubectl config set-context hoth-admin  --cluster="$CLUSTER" --user="$USER_NAME" --namespace=hoth  >/dev/null
kubectl config set-context endor-admin --cluster="$CLUSTER" --user="$USER_NAME" --namespace=endor >/dev/null
kubectl config use-context hoth-admin >/dev/null

# Repartir d'un etat propre
rm -f /root/pod.yaml

exit 0
