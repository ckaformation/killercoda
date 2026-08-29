#!/bin/bash
WEDGE_IP=$(kubectl get pod wedge -n mustafar -o jsonpath='{.status.podIP}' 2>/dev/null)
if [ -z "$WEDGE_IP" ]; then
  echo "Impossible de récupérer l'IP du pod wedge."
  exit 1
fi

BIGGS_IP=$(kubectl get pod biggs -n mustafar -o jsonpath='{.status.podIP}' 2>/dev/null)
if [ -z "$BIGGS_IP" ]; then
  echo "Impossible de récupérer l'IP du pod biggs."
  exit 1
fi

HTTP_CODE_C=$(kubectl exec lando -n kamino -- curl -s -o /dev/null -w "%{http_code}" --max-time 5 "http://${WEDGE_IP}" 2>/dev/null)
if [ "$HTTP_CODE_C" != "200" ]; then
  echo "lando (namespace kamino) ne parvient toujours pas à joindre wedge (namespace mustafar) : critère namespaceSelector (code obtenu: '$HTTP_CODE_C')."
  exit 1
fi

HTTP_CODE_D=$(kubectl exec wedge -n mustafar -- curl -s -o /dev/null -w "%{http_code}" --max-time 5 "http://${BIGGS_IP}" 2>/dev/null)
if [ "$HTTP_CODE_D" != "200" ]; then
  echo "wedge ne parvient toujours pas à joindre biggs, tous deux dans mustafar : critère podSelector (code obtenu: '$HTTP_CODE_D')."
  exit 1
fi

echo "Les deux critères OU fonctionnent : lando -> wedge (namespaceSelector) et wedge -> biggs (podSelector)."
exit 0
