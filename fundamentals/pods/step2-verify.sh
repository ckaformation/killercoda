#!/bin/bash
POD="bb-8"
SSH="ssh -o StrictHostKeyChecking=no -o ConnectTimeout=5 -o BatchMode=yes node01"

kubectl get pod "$POD" >/dev/null 2>&1 || { echo "Le pod $POD n'existe pas."; exit 1; }

NODE=$(kubectl get pod "$POD" -o jsonpath='{.spec.nodeName}' 2>/dev/null)
if [ "$NODE" != "node01" ]; then
  echo "Le pod $POD n'est pas sur node01 (node : '$NODE')."
  exit 1
fi

ID=$($SSH "cat /root/bb-8-container-id" 2>/dev/null | tr -d '[:space:]')
if [ -z "$ID" ] || [ "${#ID}" -lt 12 ]; then
  echo "Le fichier /root/bb-8-container-id est absent ou vide sur node01."
  echo "Sur node01, lance : crictl ps --name bb-8 -q > /root/bb-8-container-id"
  exit 1
fi

RUNNING=$($SSH "crictl ps -q --name bb-8" 2>/dev/null)
if ! echo "$RUNNING" | grep -q "^${ID}"; then
  echo "L'identifiant enregistré ($ID) ne correspond à aucun container bb-8 en cours d'exécution sur node01."
  exit 1
fi

echo "Le pod $POD tourne sur node01 et son container (${ID:0:12}) est visible avec crictl."
exit 0
