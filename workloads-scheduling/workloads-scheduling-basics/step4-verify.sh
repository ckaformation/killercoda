#!/bin/bash
STRATEGY=$(kubectl get statefulset jedi-archive -o jsonpath='{.spec.updateStrategy.type}' 2>/dev/null)
if [ "$STRATEGY" != "OnDelete" ]; then
  echo "Le StatefulSet jedi-archive devrait avoir updateStrategy.type=OnDelete (obtenu: $STRATEGY)."
  exit 1
fi

SPEC_CPU=$(kubectl get statefulset jedi-archive -o jsonpath='{.spec.template.spec.containers[0].resources.requests.cpu}' 2>/dev/null)
if [ "$SPEC_CPU" != "250m" ]; then
  echo "Le template du StatefulSet devrait demander 250m de CPU (obtenu: $SPEC_CPU)."
  exit 1
fi

if ! kubectl wait --for=condition=Ready pod/jedi-archive-0 --timeout=60s >/dev/null 2>&1; then
  echo "jedi-archive-0 n'est pas encore Ready."
  exit 1
fi

POD_CPU=$(kubectl get pod jedi-archive-0 -o jsonpath='{.spec.containers[0].resources.requests.cpu}' 2>/dev/null)
if [ "$POD_CPU" != "250m" ]; then
  echo "Le pod jedi-archive-0 en cours d'exécution devrait demander 250m de CPU (obtenu: $POD_CPU) — a-t-il bien été supprimé et recréé ?"
  exit 1
fi

echo "Le CPU request a bien été mis à jour à 250m, après suppression manuelle du pod (OnDelete)."
exit 0
