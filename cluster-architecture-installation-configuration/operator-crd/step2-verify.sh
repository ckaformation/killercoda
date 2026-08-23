#!/bin/bash
if ! kubectl get crd greetings.training.example.com >/dev/null 2>&1; then
  echo "La CRD greetings.training.example.com n'existe pas encore."
  exit 1
fi

if ! kubectl get greeting bienvenue -n luke >/dev/null 2>&1; then
  echo "La ressource Greeting/bienvenue n'existe pas encore dans le namespace luke."
  exit 1
fi

TIMEOUT=40
ELAPSED=0
while [ "$ELAPSED" -lt "$TIMEOUT" ]; do
  kubectl get configmap bienvenue-greeting -n luke >/dev/null 2>&1 && break
  sleep 5
  ELAPSED=$((ELAPSED + 5))
done

if ! kubectl get configmap bienvenue-greeting -n luke >/dev/null 2>&1; then
  echo "La ConfigMap bienvenue-greeting n'a pas encore été créée par l'opérateur dans luke (le polling a lieu toutes les 10s, patiente un peu si tu relances)."
  exit 1
fi

MESSAGE=$(kubectl get configmap bienvenue-greeting -n luke -o jsonpath='{.data.message}' 2>/dev/null)
EXPECTED=$(kubectl get greeting bienvenue -n luke -o jsonpath='{.spec.message}' 2>/dev/null)
if [ "$MESSAGE" != "$EXPECTED" ]; then
  echo "Le contenu de la ConfigMap ('$MESSAGE') ne correspond pas au message du Greeting ('$EXPECTED')."
  exit 1
fi

echo "La CRD, la ressource personnalisée et la ConfigMap générée par l'opérateur sont toutes correctes."
exit 0
