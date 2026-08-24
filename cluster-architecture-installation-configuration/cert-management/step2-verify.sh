#!/bin/bash
START_DATE=$(openssl x509 -in /etc/kubernetes/pki/apiserver.crt -noout -startdate 2>/dev/null | cut -d= -f2)
if [ -z "$START_DATE" ]; then
  echo "Impossible de lire la date de début de validité de apiserver.crt."
  exit 1
fi

START_EPOCH=$(date -d "$START_DATE" +%s 2>/dev/null)
NOW_EPOCH=$(date +%s)
if [ -z "$START_EPOCH" ]; then
  echo "Impossible d'interpréter la date '$START_DATE'."
  exit 1
fi

DIFF=$((NOW_EPOCH - START_EPOCH))
if [ "$DIFF" -gt 900 ]; then
  echo "apiserver.crt ne semble pas avoir été renouvelé récemment (date de début: $START_DATE)."
  exit 1
fi

if ! kubectl wait --for=condition=Ready node --all --timeout=90s >/dev/null 2>&1; then
  echo "Le nœud n'est pas encore Ready après le redémarrage du control-plane."
  exit 1
fi

CP_COUNT=$(kubectl get pods -n kube-system -l tier=control-plane --no-headers 2>/dev/null | grep -c Running)
if [ "$CP_COUNT" -lt 4 ]; then
  echo "Il devrait y avoir 4 pods control-plane Running dans kube-system (trouvés: $CP_COUNT)."
  exit 1
fi

echo "Les certificats ont été renouvelés et le control-plane est de nouveau opérationnel."
exit 0
