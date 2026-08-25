#!/bin/bash
if kubectl get pod rebel-commander -n rebellion >/dev/null 2>&1; then
  echo "rebel-commander (priorité la plus haute, level2) existe encore dans rebellion : il devrait être supprimé."
  exit 1
fi

if ! kubectl get pod x-wing-pilot -n rebellion >/dev/null 2>&1; then
  echo "x-wing-pilot (level1) devrait toujours exister dans rebellion."
  exit 1
fi

echo "Le pod le plus prioritaire (rebel-commander) a bien été supprimé."
exit 0
