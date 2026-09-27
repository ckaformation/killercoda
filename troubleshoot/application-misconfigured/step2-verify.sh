#!/bin/bash
NS="outer-rim"
DEPLOY="long-range-probe"

NODE_NAME=$(kubectl get deployment "$DEPLOY" -n "$NS" -o jsonpath='{.spec.template.spec.nodeName}' 2>/dev/null)
if [ "$NODE_NAME" = "probe-station-7" ]; then
  echo "❌ nodeName pointe encore vers le nœud inexistant probe-station-7"
  exit 1
fi
echo "✅ nodeName corrigé ou retiré"

echo "Attente de la stabilisation du Deployment..."
if ! kubectl -n "$NS" rollout status deployment/"$DEPLOY" --timeout=90s; then
  echo "❌ Le pod n'est pas Running/Ready"
  exit 1
fi
echo "✅ Pod Running/Ready"

exit 0
