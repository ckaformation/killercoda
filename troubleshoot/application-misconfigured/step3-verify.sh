#!/bin/bash
NS="endor"
DEPLOY="ewok-patrol"

SA_NAME=$(kubectl get deployment "$DEPLOY" -n "$NS" -o jsonpath='{.spec.template.spec.serviceAccountName}' 2>/dev/null)
if [ "$SA_NAME" = "imperial-clearance" ]; then
  echo "❌ serviceAccountName pointe encore vers le ServiceAccount inexistant imperial-clearance"
  exit 1
fi
echo "✅ serviceAccountName corrigé"

if [ -n "$SA_NAME" ]; then
  if ! kubectl get serviceaccount "$SA_NAME" -n "$NS" >/dev/null 2>&1; then
    echo "❌ Le ServiceAccount '$SA_NAME' n'existe pas dans $NS"
    exit 1
  fi
  echo "✅ ServiceAccount '$SA_NAME' existe bien"
fi

echo "Attente de la stabilisation du Deployment..."
if ! kubectl -n "$NS" rollout status deployment/"$DEPLOY" --timeout=90s; then
  echo "❌ Le pod n'est pas Running/Ready"
  exit 1
fi
echo "✅ Pod Running/Ready"

exit 0
