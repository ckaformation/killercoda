#!/bin/bash
for NS in tatooine alderaan; do
  COUNT=$(kubectl get networkpolicy -n "$NS" --no-headers 2>/dev/null | wc -l)
  if [ "$COUNT" -lt 1 ]; then
    echo "Aucune NetworkPolicy trouvée dans le namespace $NS."
    exit 1
  fi
done

OBIWAN_IP=$(kubectl get pod obi-wan -n tatooine -o jsonpath='{.status.podIP}' 2>/dev/null)
if [ -z "$OBIWAN_IP" ]; then
  echo "Impossible de récupérer l'IP du pod obi-wan."
  exit 1
fi

if kubectl exec luke -n tatooine -- curl -s -o /dev/null --max-time 5 "http://${OBIWAN_IP}" 2>/dev/null; then
  echo "luke peut encore joindre obi-wan : la politique de deny par défaut ne semble pas appliquée dans tatooine."
  exit 1
fi

echo "Le trafic intra-namespace est bien bloqué par défaut dans tatooine."
exit 0
