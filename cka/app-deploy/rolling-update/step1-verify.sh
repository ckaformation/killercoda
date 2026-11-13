#!/bin/bash
D="millennium-falcon"

kubectl get deployment "$D" >/dev/null 2>&1 || { echo "Le Deployment $D est introuvable."; exit 1; }

TYPE=$(kubectl get deployment "$D" -o jsonpath='{.spec.strategy.type}' 2>/dev/null)
if [ "$TYPE" != "RollingUpdate" ]; then
  echo "La stratégie de $D est '$TYPE' : elle doit être RollingUpdate."
  exit 1
fi

SURGE=$(kubectl get deployment "$D" -o jsonpath='{.spec.strategy.rollingUpdate.maxSurge}' 2>/dev/null)
if [ "$SURGE" != "1" ]; then
  echo "maxSurge vaut '$SURGE' : il doit valoir 1."
  exit 1
fi

UNAVAIL=$(kubectl get deployment "$D" -o jsonpath='{.spec.strategy.rollingUpdate.maxUnavailable}' 2>/dev/null)
if [ "$UNAVAIL" != "0" ] && [ "$UNAVAIL" != "0%" ]; then
  echo "maxUnavailable vaut '$UNAVAIL' : il doit valoir 0."
  exit 1
fi

RELEASE=$(kubectl get deployment "$D" -o jsonpath='{.spec.template.spec.containers[0].env[?(@.name=="APP_RELEASE")].value}' 2>/dev/null)
if [ -z "$RELEASE" ] || [ "$RELEASE" = "v2" ]; then
  echo "La variable APP_RELEASE vaut encore '$RELEASE' : change sa valeur pour déclencher un rollout."
  exit 1
fi

if ! kubectl rollout status deployment/"$D" --timeout=90s >/dev/null 2>&1; then
  echo "Le rollout de $D n'est pas terminé. Lance : kubectl rollout status deployment/$D"
  exit 1
fi

REVISION=$(kubectl get deployment "$D" -o jsonpath='{.metadata.annotations.deployment\.kubernetes\.io/revision}' 2>/dev/null)
if [ -z "$REVISION" ] || [ "$REVISION" -lt 2 ]; then
  echo "Aucune nouvelle révision n'a été créée pour $D."
  exit 1
fi

echo "$D est en RollingUpdate (maxSurge 1, maxUnavailable 0) et la nouvelle version (APP_RELEASE=$RELEASE) est déployée."
exit 0
