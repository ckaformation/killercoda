#!/bin/bash
ANTIAFFINITY_LABEL=$(kubectl get pod luke -o jsonpath='{.spec.affinity.podAntiAffinity.requiredDuringSchedulingIgnoredDuringExecution[0].labelSelector.matchLabels.app}' 2>/dev/null)
if [ "$ANTIAFFINITY_LABEL" != "yoda" ]; then
  echo "luke devrait avoir une podAntiAffinity ciblant app=yoda (obtenu: '$ANTIAFFINITY_LABEL')."
  exit 1
fi

TOPOLOGY=$(kubectl get pod luke -o jsonpath='{.spec.affinity.podAntiAffinity.requiredDuringSchedulingIgnoredDuringExecution[0].topologyKey}' 2>/dev/null)
if [ "$TOPOLOGY" != "kubernetes.io/hostname" ]; then
  echo "Le topologyKey devrait être kubernetes.io/hostname (obtenu: '$TOPOLOGY')."
  exit 1
fi

if ! kubectl wait --for=condition=Ready pod/luke --timeout=60s >/dev/null 2>&1; then
  echo "luke n'est pas encore Ready."
  exit 1
fi

LUKE_NODE=$(kubectl get pod luke -o jsonpath='{.spec.nodeName}' 2>/dev/null)
if [ "$LUKE_NODE" != "controlplane" ]; then
  echo "luke devrait être sur controlplane, le seul nœud sans pod app=yoda (obtenu: '$LUKE_NODE')."
  exit 1
fi

echo "luke a bien été créé avec une pod anti-affinity contre yoda, et évite bien node01."
exit 0
