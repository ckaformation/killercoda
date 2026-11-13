#!/bin/bash
if ! kubectl wait --for=condition=Available deployment/x-wing-fleet --timeout=60s >/dev/null 2>&1; then
  echo "Le Deployment x-wing-fleet n'est pas encore Available."
  exit 1
fi

VALUE=$(kubectl get deployment x-wing-fleet -o jsonpath='{.spec.template.spec.containers[0].env[0].value}' 2>/dev/null)
if [ "$VALUE" != "v1" ]; then
  echo "Le pod template devrait porter SQUADRON_VERSION=v1 après le rollback (obtenu: $VALUE)."
  exit 1
fi

RUNNING_VALUE=$(kubectl get pods -l app=x-wing-fleet -o jsonpath='{.items[0].spec.containers[0].env[0].value}' 2>/dev/null)
if [ "$RUNNING_VALUE" != "v1" ]; then
  echo "Les pods en cours d'exécution ne portent pas encore SQUADRON_VERSION=v1 (obtenu: $RUNNING_VALUE)."
  exit 1
fi

echo "Le rollback vers le contenu de la révision 1 a bien été appliqué."
exit 0
