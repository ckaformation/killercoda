#!/bin/bash
SPEC_CPU=$(kubectl get statefulset jedi-archive -o jsonpath='{.spec.template.spec.containers[0].resources.requests.cpu}' 2>/dev/null)
if [ "$SPEC_CPU" != "100m" ]; then
  echo "Le template du StatefulSet devrait être revenu à 100m de CPU (obtenu: $SPEC_CPU)."
  exit 1
fi

if ! kubectl wait --for=condition=Ready pod/jedi-archive-0 --timeout=60s >/dev/null 2>&1; then
  echo "jedi-archive-0 n'est pas encore Ready."
  exit 1
fi

POD_CPU=$(kubectl get pod jedi-archive-0 -o jsonpath='{.spec.containers[0].resources.requests.cpu}' 2>/dev/null)
if [ "$POD_CPU" != "100m" ]; then
  echo "Le pod jedi-archive-0 en cours d'exécution devrait demander 100m de CPU (obtenu: $POD_CPU) — a-t-il bien été supprimé et recréé après le rollback ?"
  exit 1
fi

echo "Le rollback du StatefulSet est effectif : CPU request revenu à 100m."
exit 0
