#!/bin/bash
if [ ! -f /root/.prep-done ]; then
  echo "❌ L'environnement n'est pas encore prêt"
  exit 1
fi

SC="retain-storage"

if ! kubectl get storageclass "$SC" >/dev/null 2>&1; then
  echo "❌ StorageClass $SC introuvable"
  exit 1
fi
echo "✅ StorageClass $SC trouvée"

PROVISIONER=$(kubectl get storageclass "$SC" -o jsonpath='{.provisioner}')
if [ "$PROVISIONER" != "rancher.io/local-path" ]; then
  echo "❌ Provisioner attendu rancher.io/local-path, trouvé $PROVISIONER"
  exit 1
fi
echo "✅ Provisioner correct"

RECLAIM=$(kubectl get storageclass "$SC" -o jsonpath='{.reclaimPolicy}')
if [ "$RECLAIM" != "Retain" ]; then
  echo "❌ reclaimPolicy attendu Retain, trouvé $RECLAIM"
  exit 1
fi
echo "✅ reclaimPolicy correct (Retain)"

BINDING=$(kubectl get storageclass "$SC" -o jsonpath='{.volumeBindingMode}')
if [ "$BINDING" != "WaitForFirstConsumer" ]; then
  echo "❌ volumeBindingMode attendu WaitForFirstConsumer, trouvé $BINDING"
  exit 1
fi
echo "✅ volumeBindingMode correct (WaitForFirstConsumer)"

exit 0
