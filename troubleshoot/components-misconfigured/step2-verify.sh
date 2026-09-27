#!/bin/bash
NODE01_STATUS=$(kubectl get node node01 -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' 2>/dev/null)

if [ "$NODE01_STATUS" != "True" ]; then
  echo "❌ node01 n'est pas Ready (statut: '$NODE01_STATUS')"
  exit 1
fi
echo "✅ node01 est Ready"

exit 0
