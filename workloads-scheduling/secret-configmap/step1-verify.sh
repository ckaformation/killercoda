#!/bin/bash
MOUNT_PATH=$(kubectl get deployment death-star-plans -o jsonpath='{.spec.template.spec.initContainers[0].volumeMounts[?(@.name=="credentials")].mountPath}' 2>/dev/null)
if [ "$MOUNT_PATH" != "/credentials" ]; then
  echo "Le mountPath du volume 'credentials' dans l'init container devrait être /credentials (obtenu: '$MOUNT_PATH')."
  exit 1
fi

if ! kubectl wait --for=condition=Ready pod -l app=death-star-plans --timeout=60s >/dev/null 2>&1; then
  echo "Le pod n'est pas encore Ready."
  exit 1
fi

POD=$(kubectl get pod -l app=death-star-plans -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
USERNAME=$(kubectl exec "$POD" -c nginx -- cat /config/username 2>/dev/null)
if [ "$USERNAME" != "obi-wan" ]; then
  echo "/config/username ne contient pas la valeur attendue (obtenu: '$USERNAME')."
  exit 1
fi

echo "Le mountPath est corrigé : l'init container a bien copié les credentials."
exit 0
