#!/bin/bash
DESIRED=$(kubectl get daemonset probe-droid -n hoth -o jsonpath='{.status.desiredNumberScheduled}' 2>/dev/null)
if [ "$DESIRED" != "2" ]; then
  echo "Le DaemonSet devrait cibler 2 nœuds pour l'instant (obtenu: '$DESIRED')."
  exit 1
fi

READY=$(kubectl get daemonset probe-droid -n hoth -o jsonpath='{.status.numberReady}' 2>/dev/null)
if [ "$READY" != "2" ]; then
  echo "Le DaemonSet n'a pas encore 2 pods Ready (obtenu: '$READY')."
  exit 1
fi

if [ ! -f /var/log/probe-droid/scan-report.txt ]; then
  echo "/var/log/probe-droid/scan-report.txt est introuvable sur controlplane."
  exit 1
fi

CONTENT_N01=$(ssh -o StrictHostKeyChecking=no -o ConnectTimeout=5 -o BatchMode=yes node01 "cat /var/log/probe-droid/scan-report.txt" 2>/dev/null)
if [ -z "$CONTENT_N01" ]; then
  echo "/var/log/probe-droid/scan-report.txt est introuvable sur node01."
  exit 1
fi

echo "Le DaemonSet tourne sur les deux nœuds et écrit bien son fichier via le hostPath."
exit 0
