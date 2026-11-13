#!/bin/bash
D="echo-base"
FILE="/root/pod-ip.txt"

kubectl get deployment "$D" >/dev/null 2>&1 || { echo "Le Deployment $D n'existe pas : la préparation de l'environnement n'est peut-être pas terminée."; exit 1; }

AVAILABLE=$(kubectl get deployment "$D" -o jsonpath='{.status.availableReplicas}' 2>/dev/null)
if [ "$AVAILABLE" != "3" ]; then
  echo "Seulement ${AVAILABLE:-0} pod(s) sur 3 sont disponibles. Attends quelques secondes (k rollout status deploy $D)."
  exit 1
fi

if [ ! -s "$FILE" ]; then
  echo "Le fichier $FILE est absent ou vide. Enregistre-y l'IP du pod que tu as appelé : echo <IP> > $FILE"
  exit 1
fi

IP=$(tr -d '[:space:]' < "$FILE")
IPS=$(kubectl get pods -l app="$D" -o jsonpath='{.items[*].status.podIP}' 2>/dev/null)
if ! echo " $IPS " | grep -q " $IP "; then
  echo "L'adresse $IP (fichier $FILE) n'est celle d'aucun pod de $D. Vérifie avec k get pods -o wide."
  exit 1
fi

CODE=$(curl -s -o /dev/null -w '%{http_code}' --max-time 5 "http://$IP")
if [ "$CODE" != "200" ]; then
  echo "Le pod $IP ne répond pas correctement (code HTTP : ${CODE:-aucun})."
  exit 1
fi

echo "Le pod d'IP $IP répond bien, et son adresse est enregistrée dans $FILE."
exit 0
