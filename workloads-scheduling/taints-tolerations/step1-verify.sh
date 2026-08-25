#!/bin/bash
TAINT=$(kubectl get node controlplane -o jsonpath='{.spec.taints[?(@.key=="empire")].effect}' 2>/dev/null)
if [ "$TAINT" != "NoSchedule" ]; then
  echo "controlplane devrait porter le taint empire=occupied:NoSchedule (obtenu: '$TAINT')."
  exit 1
fi

if ! kubectl rollout status deployment/millennium-falcon --timeout=90s >/dev/null 2>&1; then
  echo "millennium-falcon n'est pas encore stabilisé."
  exit 1
fi
if ! kubectl rollout status deployment/x-wing-squadron --timeout=90s >/dev/null 2>&1; then
  echo "x-wing-squadron n'est pas encore stabilisé."
  exit 1
fi

for pod in $(kubectl get pods -l 'app in (millennium-falcon,x-wing-squadron)' -o jsonpath='{.items[*].metadata.name}' 2>/dev/null); do
  NODE=$(kubectl get pod "$pod" -o jsonpath='{.spec.nodeName}' 2>/dev/null)
  if [ "$NODE" != "node01" ]; then
    echo "Le pod $pod est sur '$NODE', attendu: node01 (aucun Deployment ne tolère encore le taint à ce stade)."
    exit 1
  fi
done

echo "Le taint NoSchedule est en place, tous les pods sont regroupés sur node01."
exit 0
