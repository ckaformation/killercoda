#!/bin/bash
# À lancer manuellement par l'élève en première action de l'étape 1.
SENTINEL="/root/.prep-done"

echo "Préparation de l'environnement en cours (CRDs Gateway API, Traefik, application de démo)..."
for i in $(seq 1 60); do
  if [ -f "$SENTINEL" ]; then
    echo "Environnement prêt."
    exit 0
  fi
  sleep 5
done

echo "L'environnement met plus de temps que prévu à se préparer."
echo "Relance ce script dans quelques instants : ./wait-for-prep.sh"
exit 1
