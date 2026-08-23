#!/bin/bash
if ! kubectl wait --for=condition=complete job/nettoyeur-manuel -n ops --timeout=90s >/dev/null 2>&1; then
  echo "Le job nettoyeur-manuel n'est pas encore Complete."
  exit 1
fi

for i in 1 2 3; do
  if kubectl get "pod/pod-a-nettoyer-$i" -n ops >/dev/null 2>&1; then
    echo "pod-a-nettoyer-$i existe encore : il aurait dû être supprimé par nettoyeur-manuel."
    exit 1
  fi
done

echo "nettoyeur-manuel a bien nettoyé les pods Completed."
exit 0
