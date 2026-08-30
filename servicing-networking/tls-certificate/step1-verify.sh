#!/bin/bash
NS="outer-rim"

if [ ! -f /root/.prep-done ]; then
  echo "❌ L'environnement n'est pas encore prêt"
  exit 1
fi

SECRET_TYPE=$(kubectl get secret hologram-tls -n "$NS" -o jsonpath='{.type}' 2>/dev/null)
if [ -z "$SECRET_TYPE" ]; then
  echo "❌ Secret hologram-tls introuvable dans le namespace $NS"
  exit 1
fi
if [ "$SECRET_TYPE" != "kubernetes.io/tls" ]; then
  echo "❌ Le secret hologram-tls doit être de type kubernetes.io/tls (trouvé: $SECRET_TYPE)"
  exit 1
fi
echo "✅ Secret hologram-tls présent, type kubernetes.io/tls"

CRT_B64=$(kubectl get secret hologram-tls -n "$NS" -o jsonpath='{.data.tls\.crt}' 2>/dev/null)
KEY_B64=$(kubectl get secret hologram-tls -n "$NS" -o jsonpath='{.data.tls\.key}' 2>/dev/null)
if [ -z "$CRT_B64" ] || [ -z "$KEY_B64" ]; then
  echo "❌ Le secret hologram-tls doit contenir les clés tls.crt et tls.key"
  exit 1
fi
echo "✅ Clés tls.crt et tls.key présentes"

SUBJECT=$(echo "$CRT_B64" | base64 -d | openssl x509 -noout -subject 2>/dev/null)
if ! echo "$SUBJECT" | grep -q "hologram.local"; then
  echo "❌ Le CN du certificat doit correspondre à hologram.local (sujet trouvé: $SUBJECT)"
  exit 1
fi
echo "✅ CN du certificat correct (hologram.local)"

echo "Attente de la stabilisation du Deployment hologram..."
if ! kubectl -n "$NS" rollout status deployment/hologram --timeout=60s; then
  echo "❌ Le pod hologram n'est pas Running/Ready"
  exit 1
fi
echo "✅ Le pod hologram est Running et Ready"

exit 0
