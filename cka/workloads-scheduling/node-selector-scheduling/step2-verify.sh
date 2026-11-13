#!/bin/bash
if ! kubectl wait --for=condition=Available deployment/rebel-fleet --timeout=60s >/dev/null 2>&1; then
  echo "rebel-fleet n'est pas encore Available."
  exit 1
fi
if ! kubectl wait --for=condition=Available deployment/imperial-garrison --timeout=60s >/dev/null 2>&1; then
  echo "imperial-garrison n'est pas encore Available."
  exit 1
fi

for pod in $(kubectl get pods -l app=imperial-garrison -o jsonpath='{.items[*].metadata.name}' 2>/dev/null); do
  NODE=$(kubectl get pod "$pod" -o jsonpath='{.spec.nodeName}' 2>/dev/null)
  if [ "$NODE" != "node01" ]; then
    echo "Le pod imperial-garrison $pod est sur '$NODE', attendu: node01."
    exit 1
  fi
done

for pod in $(kubectl get pods -l app=rebel-fleet -o jsonpath='{.items[*].metadata.name}' 2>/dev/null); do
  NODE=$(kubectl get pod "$pod" -o jsonpath='{.spec.nodeName}' 2>/dev/null)
  SIDE_LABEL=$(kubectl get node "$NODE" -o jsonpath='{.metadata.labels.side}' 2>/dev/null)
  if [ "$SIDE_LABEL" != "dark" ]; then
    echo "Le pod rebel-fleet $pod est sur '$NODE', qui ne porte pas side=dark."
    exit 1
  fi
done

echo "Les deux Deployments sont correctement placés selon leur nodeSelector."
exit 0
