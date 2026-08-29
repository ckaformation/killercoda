#!/bin/bash
CHEWIE_IP=$(kubectl get pod chewie -n endor -o jsonpath='{.status.podIP}' 2>/dev/null)
if [ -z "$CHEWIE_IP" ]; then
  echo "Impossible de récupérer l'IP du pod chewie."
  exit 1
fi

HTTP_CODE=$(kubectl exec han -n dagobah -- curl -s -o /dev/null -w "%{http_code}" --max-time 5 "http://${CHEWIE_IP}" 2>/dev/null)
if [ "$HTTP_CODE" != "200" ]; then
  echo "han ne parvient toujours pas à joindre chewie (code obtenu: '$HTTP_CODE')."
  exit 1
fi

echo "han peut maintenant joindre chewie : la NetworkPolicy est corrigée."
exit 0
