#!/bin/bash
if ! kubectl get pod flagship -n empire >/dev/null 2>&1; then
  echo "Le pod flagship n'existe pas encore dans empire."
  exit 1
fi

PRIORITY_CLASS=$(kubectl get pod flagship -n empire -o jsonpath='{.spec.priorityClassName}' 2>/dev/null)
if [ "$PRIORITY_CLASS" != "level3" ]; then
  echo "flagship devrait avoir priorityClassName=level3 (obtenu: '$PRIORITY_CLASS')."
  exit 1
fi

MEMORY_REQUEST=$(kubectl get pod flagship -n empire -o jsonpath='{.spec.containers[0].resources.requests.memory}' 2>/dev/null)
if [ "$MEMORY_REQUEST" != "1Gi" ]; then
  echo "flagship devrait demander 1Gi de mémoire (obtenu: '$MEMORY_REQUEST')."
  exit 1
fi

if ! kubectl wait --for=condition=Ready pod/flagship -n empire --timeout=60s >/dev/null 2>&1; then
  echo "flagship n'est pas encore Ready."
  exit 1
fi

if kubectl get pod star-destroyer -n empire >/dev/null 2>&1; then
  echo "star-destroyer existe encore dans empire : il devrait avoir été préempté par flagship."
  exit 1
fi

echo "flagship tourne, et star-destroyer a bien été préempté pour lui faire de la place."
exit 0
