#!/bin/bash
NS="kessel-run"

HPA_NAME=$(kubectl get hpa -n "$NS" -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
if [ -z "$HPA_NAME" ]; then
  echo "❌ Aucun HPA trouvé dans $NS"
  exit 1
fi

CURRENT=$(kubectl get hpa "$HPA_NAME" -n "$NS" -o jsonpath='{.status.currentReplicas}' 2>/dev/null)
if [ -z "$CURRENT" ] || [ "$CURRENT" -le 10 ] 2>/dev/null; then
  echo "❌ Le HPA n'a pas encore scalé au-delà de 10 replicas (actuel: '$CURRENT')"
  echo "As-tu bien généré de la charge CPU sur plusieurs pods (stress --cpu 1) ?"
  exit 1
fi
echo "✅ Le HPA a scalé au-delà de son minimum ($CURRENT replicas)"

exit 0
