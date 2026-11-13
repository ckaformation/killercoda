#!/bin/bash
NS="jedi-temple"
DEPLOY="archive-terminal"

CM_REF=$(kubectl get deployment "$DEPLOY" -n "$NS" -o jsonpath='{.spec.template.spec.containers[0].env[?(@.name=="GREETING")].valueFrom.configMapKeyRef.name}' 2>/dev/null)
if [ "$CM_REF" != "archive-config" ]; then
  echo "❌ Le Deployment référence encore le mauvais ConfigMap (trouvé: '$CM_REF', attendu: archive-config)"
  exit 1
fi
echo "✅ Référence ConfigMap corrigée"

echo "Attente de la stabilisation du Deployment..."
if ! kubectl -n "$NS" rollout status deployment/"$DEPLOY" --timeout=90s; then
  echo "❌ Le pod n'est pas Running/Ready"
  exit 1
fi
echo "✅ Pod Running/Ready"

exit 0
