#!/bin/bash
D="death-star"

kubectl get deployment "$D" >/dev/null 2>&1 || { echo "Le Deployment $D est introuvable."; exit 1; }

PAUSED=$(kubectl get deployment "$D" -o jsonpath='{.spec.paused}' 2>/dev/null)
if [ "$PAUSED" = "true" ]; then
  echo "Le rollout de $D est toujours en pause."
  exit 1
fi

RELEASE=$(kubectl get deployment "$D" -o jsonpath='{.spec.template.spec.containers[0].env[?(@.name=="APP_RELEASE")].value}' 2>/dev/null)
if [ "$RELEASE" != "v2" ]; then
  echo "La variable APP_RELEASE de $D vaut '$RELEASE' : la modification attendue (v2) ne doit pas être annulée."
  exit 1
fi

if ! kubectl rollout status deployment/"$D" --timeout=90s >/dev/null 2>&1; then
  echo "Le rollout de $D n'est pas terminé. Lance : kubectl rollout status deployment/$D"
  exit 1
fi

REVISION=$(kubectl get deployment "$D" -o jsonpath='{.metadata.annotations.deployment\.kubernetes\.io/revision}' 2>/dev/null)
if [ -z "$REVISION" ] || [ "$REVISION" -lt 2 ]; then
  echo "Aucune nouvelle révision n'a été déployée pour $D."
  exit 1
fi

echo "Le rollout de $D a repris : la révision $REVISION (APP_RELEASE=$RELEASE) est déployée."
exit 0
