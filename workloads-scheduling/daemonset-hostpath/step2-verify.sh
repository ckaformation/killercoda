#!/bin/bash
LABEL_VALUE=$(kubectl get node node01 -o jsonpath='{.metadata.labels.mission}' 2>/dev/null)
if [ "$LABEL_VALUE" != "recon" ]; then
  echo "node01 devrait porter le label mission=recon (obtenu: '$LABEL_VALUE')."
  exit 1
fi

SELECTOR_VALUE=$(kubectl get daemonset probe-droid -n hoth -o jsonpath='{.spec.template.spec.nodeSelector.mission}' 2>/dev/null)
if [ "$SELECTOR_VALUE" != "recon" ]; then
  echo "Le DaemonSet devrait avoir un nodeSelector mission=recon (obtenu: '$SELECTOR_VALUE')."
  exit 1
fi

DESIRED=$(kubectl get daemonset probe-droid -n hoth -o jsonpath='{.status.desiredNumberScheduled}' 2>/dev/null)
if [ "$DESIRED" != "1" ]; then
  echo "Le DaemonSet devrait maintenant ne cibler qu'un seul nœud (obtenu: '$DESIRED')."
  exit 1
fi

if [ -e /var/log/probe-droid ]; then
  echo "/var/log/probe-droid existe encore sur controlplane : supprime-le (rm -rf) pour vérifier qu'il ne revient pas."
  exit 1
fi

echo "Le DaemonSet ne cible plus que node01, et son ancien répertoire hostPath sur controlplane a bien disparu pour de bon."
exit 0
