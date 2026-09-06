#!/bin/bash
NS="kamino"

REPLICAS=$(kubectl get statefulset clone-vat -n "$NS" -o jsonpath='{.spec.replicas}')
if [ "$REPLICAS" != "1" ]; then
  echo "❌ Le StatefulSet clone-vat doit avoir 1 réplique (trouvé: $REPLICAS)"
  exit 1
fi
echo "✅ StatefulSet à 1 réplique"

NODE_NAME=$(kubectl get pod clone-vat-0 -n "$NS" -o jsonpath='{.spec.nodeName}' 2>/dev/null)
if [ "$NODE_NAME" != "controlplane" ]; then
  echo "❌ Le pod clone-vat-0 devrait être planifié sur controlplane (trouvé: '$NODE_NAME')"
  exit 1
fi
echo "✅ Pod planifié sur controlplane"

PV_NAME=$(kubectl get pvc data-clone-vat-0 -n "$NS" -o jsonpath='{.spec.volumeName}' 2>/dev/null)
if [ -n "$PV_NAME" ]; then
  PV_NODE=$(kubectl get pv "$PV_NAME" -o jsonpath='{.spec.nodeAffinity.required.nodeSelectorTerms[0].matchExpressions[0].values[0]}' 2>/dev/null)
  if [ -n "$PV_NODE" ] && [ "$PV_NODE" != "controlplane" ]; then
    echo "❌ Le PV $PV_NAME est encore rattaché à '$PV_NODE' au lieu de controlplane"
    exit 1
  fi
  echo "✅ Le PV est rattaché à controlplane"
fi

READY=$(kubectl get pod clone-vat-0 -n "$NS" -o jsonpath='{.status.containerStatuses[0].ready}' 2>/dev/null)
PHASE=$(kubectl get pod clone-vat-0 -n "$NS" -o jsonpath='{.status.phase}' 2>/dev/null)
if [ "$PHASE" != "Running" ] || [ "$READY" != "true" ]; then
  echo "❌ Le pod clone-vat-0 n'est pas Running/Ready (phase: $PHASE, ready: $READY)"
  exit 1
fi
echo "✅ Pod clone-vat-0 Running et Ready"

exit 0
