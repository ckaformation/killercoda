#!/bin/bash
if ! kubectl get statefulset namespace-operator -n operators >/dev/null 2>&1; then
  echo "Le StatefulSet namespace-operator n'existe pas encore."
  exit 1
fi

READY=$(kubectl get statefulset namespace-operator -n operators -o jsonpath='{.status.readyReplicas}' 2>/dev/null)
if [ "$READY" != "1" ]; then
  echo "Le StatefulSet namespace-operator n'a pas encore de replica Ready (obtenu: '$READY')."
  exit 1
fi

echo "Le StatefulSet de l'opérateur tourne correctement."
exit 0
