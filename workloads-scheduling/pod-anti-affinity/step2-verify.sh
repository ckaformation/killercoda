#!/bin/bash
YODA2_LABEL=$(kubectl get pod yoda-2 -o jsonpath='{.metadata.labels.app}' 2>/dev/null)
if [ "$YODA2_LABEL" != "yoda" ]; then
  echo "yoda-2 devrait porter le label app=yoda (obtenu: '$YODA2_LABEL')."
  exit 1
fi

YODA2_NODE=$(kubectl get pod yoda-2 -o jsonpath='{.spec.nodeName}' 2>/dev/null)
if [ "$YODA2_NODE" != "controlplane" ]; then
  echo "yoda-2 devrait avoir nodeName=controlplane (obtenu: '$YODA2_NODE')."
  exit 1
fi

if ! kubectl wait --for=condition=Ready pod/yoda-2 --timeout=60s >/dev/null 2>&1; then
  echo "yoda-2 n'est pas encore Ready."
  exit 1
fi

if ! kubectl get pod luke >/dev/null 2>&1; then
  echo "Le pod luke n'existe pas : recrée-le (kubectl delete puis apply) après avoir déployé yoda-2 pour observer le blocage."
  exit 1
fi

LUKE_PHASE=$(kubectl get pod luke -o jsonpath='{.status.phase}' 2>/dev/null)
if [ "$LUKE_PHASE" != "Pending" ]; then
  echo "luke devrait être Pending, bloqué par son anti-affinity sur les deux nœuds (obtenu: '$LUKE_PHASE'). L'as-tu bien supprimé et recréé après le déploiement de yoda-2 ?"
  exit 1
fi

LUKE_NODE=$(kubectl get pod luke -o jsonpath='{.spec.nodeName}' 2>/dev/null)
if [ -n "$LUKE_NODE" ]; then
  echo "luke ne devrait avoir aucun nodeName assigné (obtenu: '$LUKE_NODE')."
  exit 1
fi

echo "yoda-2 est bien sur controlplane, et luke reste Pending : plus aucun nœud ne satisfait son anti-affinity."
exit 0
