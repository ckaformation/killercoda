#!/bin/bash
NS="outer-rim"

CONF=$(kubectl get configmap hologram-nginx-conf -n "$NS" -o jsonpath='{.data.default\.conf}' 2>/dev/null)
if echo "$CONF" | grep -q "TLSv1.2"; then
  echo "❌ Le ConfigMap contient encore TLSv1.2 dans ssl_protocols"
  exit 1
fi
if ! echo "$CONF" | grep -q "ssl_protocols[[:space:]]*TLSv1.3;"; then
  echo "❌ ssl_protocols doit valoir exactement 'TLSv1.3;' dans le ConfigMap"
  exit 1
fi
echo "✅ ConfigMap restreint à TLSv1.3"

echo "Attente de la stabilisation du Deployment hologram..."
if ! kubectl -n "$NS" rollout status deployment/hologram --timeout=60s; then
  echo "❌ Le pod hologram n'est pas Running/Ready après la modification"
  exit 1
fi
echo "✅ Pod hologram Running/Ready"

CLUSTER_IP=$(kubectl get svc hologram -n "$NS" -o jsonpath='{.spec.clusterIP}')
if [ -z "$CLUSTER_IP" ]; then
  echo "❌ Impossible de récupérer le ClusterIP du service hologram"
  exit 1
fi

TMP_CRT=$(mktemp)
kubectl get secret hologram-tls -n "$NS" -o jsonpath='{.data.tls\.crt}' | base64 -d > "$TMP_CRT"

echo "Test curl --tlsv1.3 (doit réussir)..."
if curl -sS --max-time 5 --tlsv1.3 --cacert "$TMP_CRT" \
     --resolve "hologram.local:443:${CLUSTER_IP}" \
     https://hologram.local/ >/tmp/hologram-out13 2>&1; then
  echo "✅ TLS 1.3 accepté"
else
  echo "❌ La connexion TLS 1.3 a échoué alors qu'elle devrait réussir"
  cat /tmp/hologram-out13
  rm -f "$TMP_CRT"
  exit 1
fi

echo "Test curl --tlsv1.2 --tls-max 1.2 (doit échouer)..."
if curl -sS --max-time 5 --tlsv1.2 --tls-max 1.2 --cacert "$TMP_CRT" \
     --resolve "hologram.local:443:${CLUSTER_IP}" \
     https://hologram.local/ >/tmp/hologram-out12 2>&1; then
  echo "❌ La connexion en TLS 1.2 a réussi alors qu'elle devrait échouer"
  rm -f "$TMP_CRT"
  exit 1
else
  echo "✅ La connexion TLS 1.2 échoue bien comme attendu"
fi

rm -f "$TMP_CRT"
exit 0
