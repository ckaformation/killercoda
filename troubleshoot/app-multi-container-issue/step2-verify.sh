#!/bin/bash
NS="tatooine"
DEPLOY="twin-suns"

IMAGE=$(kubectl get deployment "$DEPLOY" -n "$NS" -o jsonpath='{range .spec.template.spec.containers[*]}{.image}{"\n"}{end}' 2>/dev/null | grep -i whoami)
if [ -z "$IMAGE" ]; then
  echo "❌ Aucun conteneur n'utilise une image traefik/whoami"
  exit 1
fi
if [ "$IMAGE" != "traefik/whoami:v1.11" ]; then
  echo "❌ Image attendue traefik/whoami:v1.11, trouvée '$IMAGE'"
  exit 1
fi
echo "✅ Image traefik/whoami:v1.11 trouvée"

ARGS=$(kubectl get deployment "$DEPLOY" -n "$NS" -o jsonpath='{range .spec.template.spec.containers[?(@.image=="traefik/whoami:v1.11")]}{.args}{end}' 2>/dev/null)
if ! echo "$ARGS" | grep -q -- "--port" || ! echo "$ARGS" | grep -q "8080"; then
  echo "❌ L'argument --port 8080 n'est pas correctement défini (trouvé: '$ARGS')"
  exit 1
fi
echo "✅ Argument --port 8080 présent"

echo "Attente de la stabilisation du Deployment..."
if ! kubectl -n "$NS" rollout status deployment/"$DEPLOY" --timeout=90s; then
  echo "❌ Le déploiement n'est pas Running/Ready"
  exit 1
fi
echo "✅ Déploiement Running/Ready (2/2)"

exit 0
