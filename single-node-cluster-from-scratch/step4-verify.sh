#!/bin/bash
kubectl get node node01 >/dev/null 2>&1 || { echo "node01 n'a pas encore rejoint le cluster."; exit 1; }
if ! kubectl wait --for=condition=Ready node/node01 --timeout=180s >/dev/null 2>&1; then
  echo "node01 a rejoint le cluster mais n'est pas encore Ready."
  exit 1
fi
echo "node01 a rejoint le cluster et est Ready."
exit 0
