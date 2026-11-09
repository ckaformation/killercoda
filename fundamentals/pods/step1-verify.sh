#!/bin/bash
POD="bb-8"

kubectl get pod "$POD" >/dev/null 2>&1 || { echo "Le pod $POD n'existe pas. Crée-le avec k run."; exit 1; }

IMAGE=$(kubectl get pod "$POD" -o jsonpath='{.spec.containers[0].image}' 2>/dev/null)
if [ "$IMAGE" != "nginx:alpine" ]; then
  echo "Le pod $POD utilise l'image '$IMAGE' : l'image attendue est nginx:alpine."
  exit 1
fi

PHASE=$(kubectl get pod "$POD" -o jsonpath='{.status.phase}' 2>/dev/null)
if [ "$PHASE" != "Running" ]; then
  echo "Le pod $POD n'est pas encore Running (statut : $PHASE). Attends quelques secondes."
  exit 1
fi

READY=$(kubectl get pod "$POD" -o jsonpath='{.status.containerStatuses[0].ready}' 2>/dev/null)
if [ "$READY" != "true" ]; then
  echo "Le container du pod $POD n'est pas encore prêt."
  exit 1
fi

echo "Le pod $POD (nginx:alpine) est créé et Running."
exit 0
