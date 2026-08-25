#!/bin/bash
AFFINITY_LABEL=$(kubectl get pod luke -o jsonpath='{.spec.affinity.podAffinity.requiredDuringSchedulingIgnoredDuringExecution[0].labelSelector.matchLabels.app}' 2>/dev/null)
if [ "$AFFINITY_LABEL" != "yoda" ]; then
  echo "luke devrait avoir une podAffinity ciblant app=yoda (obtenu: '$AFFINITY_LABEL')."
  exit 1
fi

TOPOLOGY=$(kubectl get pod luke -o jsonpath='{.spec.affinity.podAffinity.requiredDuringSchedulingIgnoredDuringExecution[0].topologyKey}' 2>/dev/null)
if [ "$TOPOLOGY" != "kubernetes.io/hostname" ]; then
  echo "Le topologyKey devrait être kubernetes.io/hostname (obtenu: '$TOPOLOGY')."
  exit 1
fi

if ! kubectl wait --for=condition=Ready pod/luke --timeout=60s >/dev/null 2>&1; then
  echo "luke n'est pas encore Ready."
  exit 1
fi

YODA_NODE=$(kubectl get pod yoda -o jsonpath='{.spec.nodeName}' 2>/dev/null)
LUKE_NODE=$(kubectl get pod luke -o jsonpath='{.spec.nodeName}' 2>/dev/null)
if [ "$YODA_NODE" != "$LUKE_NODE" ]; then
  echo "luke ($LUKE_NODE) devrait être sur le même nœud que yoda ($YODA_NODE)."
  exit 1
fi

echo "luke a bien été recréé avec une pod affinity vers yoda, et tourne sur le même nœud."
exit 0
