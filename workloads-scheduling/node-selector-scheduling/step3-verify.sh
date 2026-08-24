#!/bin/bash
CP_SIDE=$(kubectl get node controlplane -o jsonpath='{.metadata.labels.side}' 2>/dev/null)
if [ -n "$CP_SIDE" ]; then
  echo "controlplane ne devrait plus porter le label 'side' (trouvé: '$CP_SIDE')."
  exit 1
fi

if ! kubectl rollout status deployment/rebel-fleet --timeout=90s >/dev/null 2>&1; then
  echo "rebel-fleet n'est pas encore stabilisé après le rollout restart."
  exit 1
fi
if ! kubectl rollout status deployment/imperial-garrison --timeout=90s >/dev/null 2>&1; then
  echo "imperial-garrison n'est pas encore stabilisé après le rollout restart."
  exit 1
fi

for pod in $(kubectl get pods -l 'app in (rebel-fleet,imperial-garrison)' -o jsonpath='{.items[*].metadata.name}' 2>/dev/null); do
  NODE=$(kubectl get pod "$pod" -o jsonpath='{.spec.nodeName}' 2>/dev/null)
  if [ "$NODE" != "node01" ]; then
    echo "Le pod $pod est sur '$NODE', attendu: node01 (tous les pods devraient converger sur node01)."
    exit 1
  fi
done

echo "Les 4 pods sont bien tous regroupés sur node01."
exit 0
