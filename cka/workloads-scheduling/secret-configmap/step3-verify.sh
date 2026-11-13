#!/bin/bash
if ! kubectl get configmap death-star-plans-config >/dev/null 2>&1; then
  echo "Le ConfigMap death-star-plans-config n'existe pas encore."
  exit 1
fi

if ! kubectl wait --for=condition=Ready pod -l app=death-star-plans --timeout=90s >/dev/null 2>&1; then
  echo "Le pod n'est pas encore Ready."
  exit 1
fi

POD=$(kubectl get pod -l app=death-star-plans -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
CONTENT=$(kubectl exec "$POD" -c nginx -- cat /etc/briefing/briefing.txt 2>/dev/null)
if [ -z "$CONTENT" ]; then
  echo "/etc/briefing/briefing.txt est introuvable dans le conteneur nginx : le ConfigMap est-il bien monté ?"
  exit 1
fi

echo "Le ConfigMap est bien monté et son contenu est accessible dans le conteneur nginx."
exit 0
