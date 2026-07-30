#!/bin/bash
if ! kubectl wait --for=condition=Ready pod -l app=nginx-test --timeout=120s >/dev/null 2>&1; then
  echo "Le pod nginx-test n'est pas encore Running."
  exit 1
fi

NODEPORT=$(kubectl get svc nginx-test -o jsonpath='{.spec.ports[0].nodePort}' 2>/dev/null)
if [ -z "$NODEPORT" ]; then
  echo "Le service nginx-test (NodePort) n'existe pas encore."
  exit 1
fi

HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" --max-time 5 "http://localhost:${NODEPORT}")
if [ "$HTTP_CODE" != "200" ]; then
  echo "Le service ne répond pas correctement (code HTTP: ${HTTP_CODE})."
  exit 1
fi

echo "Le cluster fonctionne : le pod de test est Running et le service répond 200."
exit 0
