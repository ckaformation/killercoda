#!/bin/bash
if ! kubectl wait --for=condition=Ready pod -l app=nginx-test --timeout=120s >/dev/null 2>&1; then
  echo "Le pod nginx-test n'est pas encore Running."
  exit 1
fi
echo "Le cluster fonctionne : le pod de test est Running."
exit 0
