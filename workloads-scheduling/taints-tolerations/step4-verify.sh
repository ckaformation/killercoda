#!/bin/bash
TOL_NOSCHEDULE=$(kubectl get deployment millennium-falcon -o jsonpath='{.spec.template.spec.tolerations[?(@.key=="empire")].effect}' 2>/dev/null)
if [ "$TOL_NOSCHEDULE" != "NoSchedule" ]; then
  echo "millennium-falcon devrait toujours tolérer empire=occupied:NoSchedule (obtenu: '$TOL_NOSCHEDULE')."
  exit 1
fi

TOL_NOEXECUTE=$(kubectl get deployment millennium-falcon -o jsonpath='{.spec.template.spec.tolerations[?(@.key=="order66")].effect}' 2>/dev/null)
if [ "$TOL_NOEXECUTE" != "NoExecute" ]; then
  echo "millennium-falcon devrait aussi tolérer order66=active:NoExecute (obtenu: '$TOL_NOEXECUTE')."
  exit 1
fi

if ! kubectl rollout status deployment/millennium-falcon --timeout=90s >/dev/null 2>&1; then
  echo "millennium-falcon n'est pas encore stabilisé."
  exit 1
fi

for pod in $(kubectl get pods -l app=x-wing-squadron -o jsonpath='{.items[*].metadata.name}' 2>/dev/null); do
  NODE=$(kubectl get pod "$pod" -o jsonpath='{.spec.nodeName}' 2>/dev/null)
  if [ "$NODE" != "node01" ]; then
    echo "Le pod x-wing-squadron $pod est sur '$NODE' : il ne devrait jamais quitter node01."
    exit 1
  fi
done

ON_CONTROLPLANE=0
for pod in $(kubectl get pods -l app=millennium-falcon -o jsonpath='{.items[*].metadata.name}' 2>/dev/null); do
  NODE=$(kubectl get pod "$pod" -o jsonpath='{.spec.nodeName}' 2>/dev/null)
  [ "$NODE" = "controlplane" ] && ON_CONTROLPLANE=$((ON_CONTROLPLANE + 1))
done

if [ "$ON_CONTROLPLANE" -eq 0 ]; then
  echo "Aucun pod millennium-falcon sur controlplane pour l'instant. Les tolerations sont bien configurées ; relance la vérification dans quelques instants."
  exit 1
fi

echo "millennium-falcon tolère les deux taints et s'est repositionné sur controlplane ; x-wing-squadron reste bloqué sur node01."
exit 0
