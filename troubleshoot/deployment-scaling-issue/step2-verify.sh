#!/bin/bash
NS="kessel-run"
DEPLOY="millennium-falcon"

QUOTA_NAME=$(kubectl get resourcequota -n "$NS" -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
if [ -n "$QUOTA_NAME" ]; then
  PODS_LIMIT=$(kubectl get resourcequota "$QUOTA_NAME" -n "$NS" -o jsonpath='{.spec.hard.pods}' 2>/dev/null)
  if [ -n "$PODS_LIMIT" ] && [ "$PODS_LIMIT" -lt 20 ] 2>/dev/null; then
    echo "❌ Le quota de pods ($PODS_LIMIT) est encore inférieur à 20"
    exit 1
  fi
fi
echo "✅ Le quota de pods autorise désormais au moins 20 pods (ou a été supprimé)"

READY=$(kubectl get deployment "$DEPLOY" -n "$NS" -o jsonpath='{.status.readyReplicas}')
if [ -z "$READY" ] || [ "$READY" -lt 10 ] 2>/dev/null; then
  echo "❌ Seulement '$READY' pods Ready, attendu au moins 10 (min du HPA)"
  exit 1
fi
echo "✅ Au moins 10 pods Ready ($READY)"

exit 0
