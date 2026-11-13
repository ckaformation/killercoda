#!/bin/bash
D="echo-base"
S="echo-base"
FILE="/root/pod-ip.txt"

if [ ! -s "$FILE" ]; then
  echo "Le fichier $FILE (étape 1) est absent ou vide."
  exit 1
fi
OLD=$(tr -d '[:space:]' < "$FILE")

IPS=$(kubectl get pods -l app="$D" -o jsonpath='{.items[*].status.podIP}' 2>/dev/null)
if echo " $IPS " | grep -q " $OLD "; then
  echo "Le pod d'IP $OLD existe encore. Supprime-le avec k delete pod <nom>."
  exit 1
fi

AVAILABLE=$(kubectl get deployment "$D" -o jsonpath='{.status.availableReplicas}' 2>/dev/null)
if [ "$AVAILABLE" != "3" ]; then
  echo "Seulement ${AVAILABLE:-0} pod(s) sur 3 sont disponibles. Attends quelques secondes que le pod de remplacement démarre."
  exit 1
fi

CLUSTER_IP=$(kubectl get svc "$S" -o jsonpath='{.spec.clusterIP}' 2>/dev/null)
if [ -z "$CLUSTER_IP" ]; then
  echo "Le Service $S n'existe plus (étape 2)."
  exit 1
fi

CODE=$(curl -s -o /dev/null -w '%{http_code}' --max-time 5 "http://$CLUSTER_IP")
if [ "$CODE" != "200" ]; then
  echo "Le Service ne répond pas sur http://$CLUSTER_IP (code HTTP : ${CODE:-aucun})."
  exit 1
fi

echo "Le pod d'IP $OLD a été remplacé, et le Service continue de répondre sur $CLUSTER_IP."
exit 0
