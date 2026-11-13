#!/bin/bash
NODE01_LABEL=$(kubectl get node node01 -o jsonpath='{.metadata.labels.order}' 2>/dev/null)
if [ "$NODE01_LABEL" != "sith" ]; then
  echo "node01 devrait porter le label order=sith (obtenu: '$NODE01_LABEL')."
  exit 1
fi

CP_LABEL=$(kubectl get node controlplane -o jsonpath='{.metadata.labels.order}' 2>/dev/null)
if [ -n "$CP_LABEL" ]; then
  echo "controlplane ne devrait pas porter de label 'order' (trouvé: '$CP_LABEL')."
  exit 1
fi

echo "Le label order=sith est bien présent sur node01 uniquement."
exit 0
