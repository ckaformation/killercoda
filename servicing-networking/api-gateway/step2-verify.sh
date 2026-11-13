#!/bin/bash
APP_NS="imagine-app"

GW_NAME=$(kubectl get gateway -n "$APP_NS" -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
[ -n "$GW_NAME" ] || { echo "❌ Gateway introuvable (étape 1 non validée ?)"; exit 1; }

ROUTE_NAME=$(kubectl get httproute -n "$APP_NS" \
  -o jsonpath='{range .items[*]}{.metadata.name}{" "}{range .spec.rules[*].matches[*].path}{.value}{" "}{end}{"\n"}{end}' \
  | grep '/api' | grep '/admin' | awk '{print $1}' | head -n1)

if [ -z "$ROUTE_NAME" ]; then
  echo "❌ Aucune HTTPRoute exposant à la fois /api et /admin trouvée dans $APP_NS"
  exit 1
fi
echo "✅ HTTPRoute trouvée : $ROUTE_NAME"

PARENT=$(kubectl get httproute "$ROUTE_NAME" -n "$APP_NS" -o jsonpath='{.spec.parentRefs[0].name}')
if [ "$PARENT" != "$GW_NAME" ]; then
  echo "❌ La HTTPRoute ne référence pas la Gateway $GW_NAME (parentRef=$PARENT)"
  exit 1
fi
echo "✅ parentRef correct ($PARENT)"

ACCEPTED=$(kubectl get httproute "$ROUTE_NAME" -n "$APP_NS" -o jsonpath='{.status.parents[0].conditions[?(@.type=="Accepted")].status}')
if [ "$ACCEPTED" != "True" ]; then
  echo "❌ HTTPRoute pas encore Accepted (status=$ACCEPTED)"
  exit 1
fi
echo "✅ HTTPRoute Accepted"

API_RESP=$(curl -s --max-time 5 http://imagine.app:30080/api || true)
if ! echo "$API_RESP" | grep -q "Welcome to the api"; then
  echo "❌ /api ne répond pas comme attendu (reçu: '$API_RESP')"
  exit 1
fi
echo "✅ /api répond correctement"

ADMIN_RESP=$(curl -s --max-time 5 http://imagine.app:30080/admin || true)
if ! echo "$ADMIN_RESP" | grep -q "Welcome to the admin"; then
  echo "❌ /admin ne répond pas comme attendu (reçu: '$ADMIN_RESP')"
  exit 1
fi
echo "✅ /admin répond correctement"

# Négatif : un chemin non déclaré ne doit pas être routé vers /api ou /admin
OTHER_CODE=$(curl -s -o /dev/null -w '%{http_code}' --max-time 5 http://imagine.app:30080/doesnotexist || true)
if [ "$OTHER_CODE" = "200" ]; then
  echo "❌ /doesnotexist ne devrait pas répondre 200"
  exit 1
fi
echo "✅ Chemin non déclaré correctement rejeté (code $OTHER_CODE)"

exit 0
