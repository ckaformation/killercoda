#!/bin/bash
test -f /tmp/.scenario-prep-done || { echo "La préparation en arrière-plan n'est pas encore terminée."; exit 1; }
kubectl get nodes >/dev/null 2>&1 || { echo "kubectl ne parvient pas à contacter le cluster."; exit 1; }
NODE_COUNT=$(kubectl get nodes --no-headers 2>/dev/null | wc -l)
if [ "$NODE_COUNT" -lt 2 ]; then
  echo "Les deux nœuds ne sont pas encore visibles dans le cluster."
  exit 1
fi
echo "Le cluster est accessible avec ses 2 nœuds."
exit 0
