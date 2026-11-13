#!/bin/bash
S="echo-base"

kubectl get svc "$S" >/dev/null 2>&1 || { echo "Le Service $S n'existe plus."; exit 1; }

TYPE=$(kubectl get svc "$S" -o jsonpath='{.spec.type}' 2>/dev/null)
if [ "$TYPE" != "NodePort" ]; then
  echo "Le Service $S est de type '$TYPE' : il doit être de type NodePort."
  exit 1
fi

NODEPORT=$(kubectl get svc "$S" -o jsonpath='{.spec.ports[0].nodePort}' 2>/dev/null)
if [ "$NODEPORT" != "30080" ]; then
  echo "Le nodePort vaut '$NODEPORT' : il doit valoir 30080."
  exit 1
fi

for NODE in controlplane node01; do
  IP=$(kubectl get node "$NODE" -o jsonpath='{.status.addresses[?(@.type=="InternalIP")].address}' 2>/dev/null)
  if [ -z "$IP" ]; then
    echo "Impossible de déterminer l'IP interne du node $NODE."
    exit 1
  fi
  CODE=$(curl -s -o /dev/null -w '%{http_code}' --max-time 5 "http://$IP:30080")
  if [ "$CODE" != "200" ]; then
    echo "Le Service ne répond pas sur http://$IP:30080 ($NODE) : code HTTP ${CODE:-aucun}."
    exit 1
  fi
done

echo "Le Service $S (NodePort 30080) répond sur l'IP de controlplane et sur celle de node01."
exit 0
