#!/bin/bash
APP_NS="imagine-app"

ROUTE_NAME=$(kubectl get httproute -n "$APP_NS" \
  -o jsonpath='{range .items[*]}{.metadata.name}{" "}{range .spec.rules[*].matches[*].path}{.value}{" "}{end}{"\n"}{end}' \
  | grep '/web' | awk '{print $1}' | head -n1)

if [ -z "$ROUTE_NAME" ]; then
  echo "❌ Aucune HTTPRoute exposant /web trouvée dans $APP_NS"
  exit 1
fi
echo "✅ HTTPRoute canary trouvée : $ROUTE_NAME"

W1=$(kubectl get httproute "$ROUTE_NAME" -n "$APP_NS" \
  -o jsonpath='{.spec.rules[0].backendRefs[?(@.name=="web-v1")].weight}')
W2=$(kubectl get httproute "$ROUTE_NAME" -n "$APP_NS" \
  -o jsonpath='{.spec.rules[0].backendRefs[?(@.name=="web-v2")].weight}')

if [ "$W1" != "75" ] || [ "$W2" != "25" ]; then
  echo "❌ Pondération attendue 75 (web-v1) / 25 (web-v2), trouvé '${W1}'/'${W2}'"
  exit 1
fi
echo "✅ Pondération 75/25 correcte"

ACCEPTED=$(kubectl get httproute "$ROUTE_NAME" -n "$APP_NS" -o jsonpath='{.status.parents[0].conditions[?(@.type=="Accepted")].status}')
if [ "$ACCEPTED" != "True" ]; then
  echo "❌ HTTPRoute pas encore Accepted (status=$ACCEPTED)"
  exit 1
fi
echo "✅ HTTPRoute Accepted"

# Vérification non déterministe assumée (comme pour le placement de pods
# dans taints-tolerations) : on ne teste pas un ratio exact, seulement
# une répartition plausible sur un échantillon plus large que les 20
# requêtes manuelles de l'élève, pour limiter la volatilité statistique.
echo "Envoi de 100 requêtes vers /web pour observer la répartition..."
V1=0; V2=0; OTHER=0
for i in $(seq 1 100); do
  R=$(curl -s --max-time 3 http://imagine.app:30080/web || true)
  case "$R" in
    *"- v1"*) V1=$((V1+1)) ;;
    *"- v2"*) V2=$((V2+1)) ;;
    *) OTHER=$((OTHER+1)) ;;
  esac
done
echo "Résultats : v1=$V1 v2=$V2 autre=$OTHER"

if [ "$V1" -eq 0 ] || [ "$V2" -eq 0 ]; then
  echo "❌ Les deux versions doivent apparaître au moins une fois sur 100 requêtes"
  exit 1
fi
if [ "$V1" -le "$V2" ]; then
  echo "❌ v1 (75%) devrait être majoritaire par rapport à v2 (25%) — répartition suspecte, relance le test"
  exit 1
fi
echo "✅ Répartition canary plausible (v1 majoritaire, v2 bien présent)"

exit 0
