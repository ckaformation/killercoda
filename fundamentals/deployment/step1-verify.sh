#!/bin/bash
D="snowspeeder"

kubectl get deployment "$D" >/dev/null 2>&1 || { echo "Le Deployment $D n'existe pas. Crée-le avec k create deployment."; exit 1; }

REPLICAS=$(kubectl get deployment "$D" -o jsonpath='{.spec.replicas}' 2>/dev/null)
if [ "$REPLICAS" != "3" ]; then
  echo "Le Deployment $D a $REPLICAS réplica(s) : il en faut 3."
  exit 1
fi

IMAGE=$(kubectl get deployment "$D" -o jsonpath='{.spec.template.spec.containers[0].image}' 2>/dev/null)
if [ "$IMAGE" != "nginx:alpine" ]; then
  echo "Le Deployment $D utilise l'image '$IMAGE' : l'image attendue est nginx:alpine."
  exit 1
fi

AVAILABLE=$(kubectl get deployment "$D" -o jsonpath='{.status.availableReplicas}' 2>/dev/null)
if [ "$AVAILABLE" != "3" ]; then
  echo "Seulement ${AVAILABLE:-0} pod(s) sur 3 sont disponibles. Attends quelques secondes (k rollout status deploy $D)."
  exit 1
fi

echo "Le Deployment $D (nginx:alpine, 3 réplicas) est créé et ses 3 pods sont disponibles."
exit 0
