#!/bin/bash
POD="bb-8"
SSH="ssh -o StrictHostKeyChecking=no -o ConnectTimeout=5 -o BatchMode=yes node01"

if kubectl get pod "$POD" >/dev/null 2>&1; then
  echo "Le pod $POD existe encore. Supprime-le avec k delete pod $POD."
  exit 1
fi

OLD=$($SSH "cat /root/bb-8-container-id" 2>/dev/null | tr -d '[:space:]')
NEW=$($SSH "cat /root/bb-8-new-container-id" 2>/dev/null | tr -d '[:space:]')

if [ -z "$OLD" ] || [ "${#OLD}" -lt 12 ]; then
  echo "Le fichier /root/bb-8-container-id (étape 2) est absent ou vide sur node01."
  exit 1
fi

if [ -z "$NEW" ] || [ "${#NEW}" -lt 12 ]; then
  echo "Le fichier /root/bb-8-new-container-id est absent ou vide sur node01."
  echo "Il doit contenir l'identifiant du container recréé par le kubelet après le crictl rm -f."
  exit 1
fi

if [ "${OLD:0:12}" = "${NEW:0:12}" ]; then
  echo "L'ancien et le nouvel identifiant de container sont identiques : le container n'a pas été supprimé puis recréé."
  exit 1
fi

if $SSH "crictl ps -a -q" 2>/dev/null | grep -q "^${OLD}"; then
  echo "L'ancien container (${OLD:0:12}) existe encore sur node01 : supprime-le avec crictl rm -f."
  exit 1
fi

if [ -n "$($SSH "crictl ps -q --name bb-8" 2>/dev/null)" ]; then
  echo "Un container bb-8 tourne encore sur node01. Attends quelques secondes que le kubelet termine la suppression du pod."
  exit 1
fi

echo "Le container a été recréé par le kubelet (${OLD:0:12} -> ${NEW:0:12}), et le pod supprimé n'est pas revenu."
exit 0
