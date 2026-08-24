#!/bin/bash
if ! kubectl get pod r2d2 >/dev/null 2>&1; then
  echo "Le pod r2d2 n'existe pas encore."
  exit 1
fi

STATUS=$(kubectl get pod r2d2 -o jsonpath='{.status.phase}' 2>/dev/null)
if [ "$STATUS" != "Running" ]; then
  echo "Le pod r2d2 n'est pas encore Running (statut: $STATUS)."
  exit 1
fi

OWNER=$(kubectl get pod r2d2 -o jsonpath='{.metadata.ownerReferences}' 2>/dev/null)
if [ -n "$OWNER" ]; then
  echo "Le pod r2d2 ne devrait avoir aucun ownerReference (trouvé: $OWNER)."
  exit 1
fi

echo "Le pod r2d2 tourne, sans contrôleur parent."
exit 0
