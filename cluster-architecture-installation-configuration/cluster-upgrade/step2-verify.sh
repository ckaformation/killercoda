#!/bin/bash
if ! kubectl get --raw /version 2>/dev/null | grep -q '"gitVersion": *"v1\.37'; then
  echo "Le control-plane n'est pas encore en v1.37.x."
  exit 1
fi
echo "Le control-plane (kube-apiserver) est bien passé en v1.37.x."
exit 0
