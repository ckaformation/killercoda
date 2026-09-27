#!/bin/bash
NS=$(helm list -A --no-headers 2>/dev/null | awk '$1=="podinfo" {print $2}')

if [ -z "$NS" ]; then
  echo "❌ Aucune release Helm 'podinfo' trouvée"
  exit 1
fi
echo "✅ Release podinfo trouvée dans le namespace $NS"

VALUES_YAML=$(helm get values podinfo -n "$NS" 2>/dev/null)
if ! echo "$VALUES_YAML" | grep -q "message: hello-helm"; then
  echo "❌ ui.message attendu 'hello-helm', introuvable dans les values :"
  echo "$VALUES_YAML"
  exit 1
fi
echo "✅ ui.message correctement défini (hello-helm)"

echo "Attente de la stabilisation du Deployment..."
if ! kubectl -n "$NS" rollout status deployment/podinfo --timeout=90s; then
  echo "❌ Le pod podinfo n'est pas Running/Ready"
  exit 1
fi
echo "✅ Pod podinfo Running/Ready"

exit 0
