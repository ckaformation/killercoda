#!/bin/bash
NS="europe-west1"
REGION="europe-west1"

CLUSTER_IP=$(kubectl get svc region-service -n "$NS" -o jsonpath='{.spec.clusterIP}' 2>/dev/null)
if [ -z "$CLUSTER_IP" ]; then
  echo "❌ Service region-service introuvable dans $NS"
  exit 1
fi
echo "✅ Service trouvé (ClusterIP: $CLUSTER_IP)"

echo "Attente de la stabilisation du Deployment..."
if ! kubectl -n "$NS" rollout status deployment/region-service --timeout=90s; then
  echo "❌ Le pod n'est pas Running/Ready"
  exit 1
fi
echo "✅ Pod Running/Ready"

RESPONSE=$(curl -s --max-time 5 "http://$CLUSTER_IP/")
if ! echo "$RESPONSE" | grep -q "$REGION"; then
  echo "❌ La réponse ne confirme pas la région $REGION (reçu: '$RESPONSE')"
  exit 1
fi
echo "✅ Réponse confirmant $REGION : $RESPONSE"

exit 0
