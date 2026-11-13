#!/bin/bash
CLUSTER_IP=$(kubectl get svc kubernetes -n default -o jsonpath='{.spec.clusterIP}' 2>/dev/null)
if [ -z "$CLUSTER_IP" ]; then
  echo "Impossible de récupérer le ClusterIP du service kubernetes."
  exit 1
fi

HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" -k --max-time 5 "https://${CLUSTER_IP}/version")
if [ -z "$HTTP_CODE" ] || [ "$HTTP_CODE" = "000" ]; then
  echo "Aucune réponse HTTP de l'API server via https://${CLUSTER_IP}/version (code: '$HTTP_CODE')."
  exit 1
fi

echo "L'API server répond correctement en HTTPS via son ClusterIP (code HTTP: $HTTP_CODE)."
exit 0
