#!/bin/bash
OBIWAN_IP=$(kubectl get pod obi-wan -n tatooine -o jsonpath='{.status.podIP}' 2>/dev/null)
if [ -z "$OBIWAN_IP" ]; then
  echo "Impossible de récupérer l'IP du pod obi-wan."
  exit 1
fi

HTTP_CODE=$(kubectl exec luke -n tatooine -- curl -s -o /dev/null -w "%{http_code}" --max-time 5 "http://${OBIWAN_IP}" 2>/dev/null)
if [ "$HTTP_CODE" != "200" ]; then
  echo "luke devrait pouvoir joindre obi-wan maintenant (code obtenu: '$HTTP_CODE')."
  exit 1
fi

echo "luke peut de nouveau joindre obi-wan : la NetworkPolicy d'autorisation fonctionne."
exit 0
