#!/bin/bash
TOKEN_B64=$(kubectl get secret death-star-plans-credentials -o jsonpath='{.data.token}' 2>/dev/null)
if [ -z "$TOKEN_B64" ]; then
  echo "Le secret death-star-plans-credentials ne contient pas encore la clé 'token'."
  exit 1
fi

if ! kubectl wait --for=condition=Ready pod -l app=death-star-plans --timeout=90s >/dev/null 2>&1; then
  echo "Le pod n'est pas encore Ready."
  exit 1
fi

POD=$(kubectl get pod -l app=death-star-plans -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
TOKEN_FILE=$(kubectl exec "$POD" -c nginx -- cat /config/token 2>/dev/null)
if [ -z "$TOKEN_FILE" ]; then
  echo "/config/token est introuvable dans le pod actuel : as-tu bien fait un 'kubectl rollout restart' après avoir modifié le secret ?"
  exit 1
fi

echo "Le secret a été mis à jour et le rollout a permis à l'init container de recopier la nouvelle clé."
exit 0
