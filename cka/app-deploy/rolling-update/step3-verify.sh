#!/bin/bash
D="tie-fighter"

kubectl get deployment "$D" >/dev/null 2>&1 || { echo "Le Deployment $D est introuvable."; exit 1; }

RELEASE=$(kubectl get deployment "$D" -o jsonpath='{.spec.template.spec.containers[0].env[?(@.name=="APP_RELEASE")].value}' 2>/dev/null)
COMMAND=$(kubectl get deployment "$D" -o jsonpath='{.spec.template.spec.containers[0].command}' 2>/dev/null)

if [ -n "$COMMAND" ]; then
  echo "Le pod template de $D contient encore la commande défectueuse de la révision 4."
  exit 1
fi

if [ "$RELEASE" != "v2" ]; then
  echo "APP_RELEASE vaut '$RELEASE' : le contenu attendu est celui de la révision 2 (APP_RELEASE=v2)."
  exit 1
fi

if ! kubectl rollout status deployment/"$D" --timeout=90s >/dev/null 2>&1; then
  echo "Le rollout de $D n'est pas terminé. Lance : kubectl rollout status deployment/$D"
  exit 1
fi

if kubectl get pods -l app="$D" --no-headers 2>/dev/null | grep -q "CrashLoopBackOff"; then
  echo "Un pod de $D est encore en CrashLoopBackOff."
  exit 1
fi

REVISION=$(kubectl get deployment "$D" -o jsonpath='{.metadata.annotations.deployment\.kubernetes\.io/revision}' 2>/dev/null)
if [ -z "$REVISION" ] || [ "$REVISION" -lt 5 ]; then
  echo "Aucun rollback n'a été enregistré pour $D (révision actuelle : ${REVISION:-inconnue})."
  exit 1
fi

echo "$D est revenu au contenu de la révision 2 (nouvelle révision $REVISION) et ses pods fonctionnent."
exit 0
