#!/bin/bash
TAINT=$(kubectl get node controlplane -o jsonpath='{.spec.taints[?(@.key=="order66")].effect}' 2>/dev/null)
if [ "$TAINT" != "NoExecute" ]; then
  echo "controlplane devrait porter le taint order66=active:NoExecute (obtenu: '$TAINT')."
  exit 1
fi

TIMEOUT=40
ELAPSED=0
while [ "$ELAPSED" -lt "$TIMEOUT" ]; do
  STILL_THERE=0
  for pod in $(kubectl get pods -l app=millennium-falcon -o jsonpath='{.items[*].metadata.name}' 2>/dev/null); do
    NODE=$(kubectl get pod "$pod" -o jsonpath='{.spec.nodeName}' 2>/dev/null)
    [ "$NODE" = "controlplane" ] && STILL_THERE=$((STILL_THERE + 1))
  done
  [ "$STILL_THERE" -eq 0 ] && break
  sleep 5
  ELAPSED=$((ELAPSED + 5))
done

if [ "$STILL_THERE" -ne 0 ]; then
  echo "$STILL_THERE pod(s) millennium-falcon sont encore sur controlplane : ils devraient avoir été évincés par le taint NoExecute."
  exit 1
fi

echo "Le taint NoExecute est en place et a bien évincé les pods millennium-falcon de controlplane."
exit 0
