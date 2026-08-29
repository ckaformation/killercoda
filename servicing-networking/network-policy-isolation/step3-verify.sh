#!/bin/bash
LEIA_IP=$(kubectl get pod leia -n alderaan -o jsonpath='{.status.podIP}' 2>/dev/null)
if [ -z "$LEIA_IP" ]; then
  echo "Impossible de récupérer l'IP du pod leia."
  exit 1
fi

HTTP_CODE_LUKE=$(kubectl exec luke -n tatooine -- curl -s -o /dev/null -w "%{http_code}" --max-time 5 "http://${LEIA_IP}" 2>/dev/null)
if [ "$HTTP_CODE_LUKE" != "200" ]; then
  echo "luke devrait pouvoir joindre leia (code obtenu: '$HTTP_CODE_LUKE')."
  exit 1
fi

if kubectl exec obi-wan -n tatooine -- curl -s -o /dev/null --max-time 5 "http://${LEIA_IP}" 2>/dev/null; then
  echo "obi-wan ne devrait PAS pouvoir joindre leia : seul luke devrait être autorisé par la NetworkPolicy (vérifie que namespaceSelector et podSelector sont bien combinés en ET, pas en OU)."
  exit 1
fi

echo "luke peut joindre leia, obi-wan ne le peut pas : la NetworkPolicy AND (namespaceSelector + podSelector) fonctionne comme prévu."
exit 0
