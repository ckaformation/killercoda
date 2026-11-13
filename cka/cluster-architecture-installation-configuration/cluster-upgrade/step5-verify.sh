#!/bin/bash
for NODE in controlplane node01; do
  VERSION=$(kubectl get node "$NODE" -o jsonpath='{.status.nodeInfo.kubeletVersion}' 2>/dev/null)
  case "$VERSION" in
    v1.36*) ;;
    *) echo "kubelet sur $NODE n'est pas encore en v1.36.x (version actuelle: $VERSION)"; exit 1 ;;
  esac

  if ! kubectl wait --for=condition=Ready "node/$NODE" --timeout=60s >/dev/null 2>&1; then
    echo "Le nœud $NODE n'est pas Ready."
    exit 1
  fi

  UNSCHEDULABLE=$(kubectl get node "$NODE" -o jsonpath='{.spec.unschedulable}' 2>/dev/null)
  if [ "$UNSCHEDULABLE" = "true" ]; then
    echo "$NODE est encore cordonné."
    exit 1
  fi
done

echo "Les deux nœuds sont en v1.36.x, Ready et schedulables : upgrade terminé."
exit 0
