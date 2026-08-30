#!/bin/bash
APP_NS="imagine-app"

if [ ! -f /root/.prep-done ]; then
  echo "❌ L'environnement n'est pas encore prêt (relance wait-for-prep.sh)"
  exit 1
fi
echo "✅ Environnement prêt"

GW_NAME=$(kubectl get gateway -n "$APP_NS" -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
if [ -z "$GW_NAME" ]; then
  echo "❌ Aucune Gateway trouvée dans le namespace $APP_NS"
  exit 1
fi
echo "✅ Gateway trouvée : $GW_NAME"

CLASS=$(kubectl get gateway "$GW_NAME" -n "$APP_NS" -o jsonpath='{.spec.gatewayClassName}')
if [ "$CLASS" != "traefik" ]; then
  echo "❌ gatewayClassName attendu 'traefik', trouvé '$CLASS'"
  exit 1
fi
echo "✅ gatewayClassName correct (traefik)"

LISTENER_MATCH=$(kubectl get gateway "$GW_NAME" -n "$APP_NS" \
  -o jsonpath='{range .spec.listeners[?(@.protocol=="HTTP")]}{.hostname}{" "}{.port}{"\n"}{end}' \
  | grep -c '^imagine\.app 80$')
if [ "$LISTENER_MATCH" -lt 1 ]; then
  echo "❌ Aucun listener HTTP port 80 avec hostname imagine.app"
  exit 1
fi
echo "✅ Listener HTTP/80/imagine.app présent"

# Négatif : la Gateway ne doit pas exposer un listener sans hostname
# (ce qui accepterait n'importe quel hostname, trop permissif pour l'exercice)
NAKED_LISTENER=$(kubectl get gateway "$GW_NAME" -n "$APP_NS" \
  -o jsonpath='{range .spec.listeners[?(@.protocol=="HTTP")]}{.hostname}{"\n"}{end}' \
  | grep -c '^$')
if [ "$NAKED_LISTENER" -gt 0 ]; then
  echo "❌ Un listener HTTP sans hostname a été trouvé : le hostname imagine.app doit être explicite"
  exit 1
fi
echo "✅ Pas de listener HTTP sans hostname"

ACCEPTED=$(kubectl get gateway "$GW_NAME" -n "$APP_NS" -o jsonpath='{.status.conditions[?(@.type=="Accepted")].status}')
PROGRAMMED=$(kubectl get gateway "$GW_NAME" -n "$APP_NS" -o jsonpath='{.status.conditions[?(@.type=="Programmed")].status}')
if [ "$ACCEPTED" != "True" ] || [ "$PROGRAMMED" != "True" ]; then
  echo "❌ Gateway pas encore Accepted/Programmed (Accepted=$ACCEPTED, Programmed=$PROGRAMMED)"
  exit 1
fi
echo "✅ Gateway Accepted et Programmed"

exit 0
