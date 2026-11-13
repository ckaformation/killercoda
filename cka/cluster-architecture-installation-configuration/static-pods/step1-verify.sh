#!/bin/bash
POD_NAME="static-web-node01"

if ! kubectl get pod "$POD_NAME" >/dev/null 2>&1; then
  echo "Le pod miroir $POD_NAME n'existe pas encore."
  exit 1
fi

STATUS=$(kubectl get pod "$POD_NAME" -o jsonpath='{.status.phase}' 2>/dev/null)
if [ "$STATUS" != "Running" ]; then
  echo "Le pod $POD_NAME n'est pas encore Running (statut: $STATUS)."
  exit 1
fi

CRICTL_CHECK=$(ssh -o StrictHostKeyChecking=no -o ConnectTimeout=5 -o BatchMode=yes node01 "crictl ps --name web -q" 2>/dev/null)
if [ -z "$CRICTL_CHECK" ]; then
  echo "Aucun conteneur nommé 'web' visible via crictl ps sur node01."
  exit 1
fi

echo "Le static pod static-web tourne correctement sur node01 (confirmé via kubectl et crictl)."
exit 0
