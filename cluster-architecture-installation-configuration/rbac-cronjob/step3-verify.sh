#!/bin/bash
if ! kubectl get sa leon-2 -n ops >/dev/null 2>&1; then
  echo "Le ServiceAccount leon-2 n'existe pas encore."
  exit 1
fi

VALUE=$(kubectl get sa leon-2 -n ops -o jsonpath='{.automountServiceAccountToken}' 2>/dev/null)
if [ "$VALUE" != "false" ]; then
  echo "leon-2 devrait avoir automountServiceAccountToken: false (obtenu: '$VALUE')"
  exit 1
fi

echo "leon-2 existe, avec automountServiceAccountToken: false."
exit 0
