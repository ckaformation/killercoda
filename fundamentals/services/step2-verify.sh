#!/bin/bash
S="echo-base"

kubectl get svc "$S" >/dev/null 2>&1 || { echo "Le Service $S n'existe pas. Crée-le avec k expose deployment."; exit 1; }

TYPE=$(kubectl get svc "$S" -o jsonpath='{.spec.type}' 2>/dev/null)
if [ "$TYPE" != "ClusterIP" ]; then
  echo "Le Service $S est de type '$TYPE' : à cette étape, il doit être de type ClusterIP."
  exit 1
fi

SELECTOR=$(kubectl get svc "$S" -o jsonpath='{.spec.selector.app}' 2>/dev/null)
if [ "$SELECTOR" != "echo-base" ]; then
  echo "Le selector du Service ne cible pas app=echo-base (valeur : '$SELECTOR')."
  exit 1
fi

PORT=$(kubectl get svc "$S" -o jsonpath='{.spec.ports[0].port}' 2>/dev/null)
if [ "$PORT" != "80" ]; then
  echo "Le Service écoute sur le port '$PORT' : il doit écouter sur le port 80."
  exit 1
fi

CLUSTER_IP=$(kubectl get svc "$S" -o jsonpath='{.spec.clusterIP}' 2>/dev/null)
if [ -z "$CLUSTER_IP" ] || [ "$CLUSTER_IP" = "None" ]; then
  echo "Le Service $S n'a pas de ClusterIP."
  exit 1
fi

CODE=$(curl -s -o /dev/null -w '%{http_code}' --max-time 5 "http://$CLUSTER_IP")
if [ "$CODE" != "200" ]; then
  echo "Le Service ne répond pas sur http://$CLUSTER_IP (code HTTP : ${CODE:-aucun})."
  exit 1
fi

echo "Le Service $S (ClusterIP $CLUSTER_IP) répond correctement."
exit 0
