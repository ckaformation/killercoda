#!/bin/bash
REGISTRY_IMAGE="localhost:5000/holocron:v1"

command -v curl >/dev/null 2>&1 || { echo "La commande curl est introuvable."; exit 1; }

# 1) Le registre répond et contient le dépôt holocron avec le tag v1
CATALOG=$(curl -s --max-time 5 http://localhost:5000/v2/_catalog)
if ! echo "$CATALOG" | grep -q '"holocron"'; then
  echo "Le registre local ne répond pas sur localhost:5000, ou ne contient pas le dépôt holocron."
  echo "Vérifie qu'il tourne (docker ps) et que tu as bien fait le docker push."
  exit 1
fi
TAGS=$(curl -s --max-time 5 http://localhost:5000/v2/holocron/tags/list)
if ! echo "$TAGS" | grep -q '"v1"'; then
  echo "Le dépôt holocron existe dans le registre, mais sans le tag v1."
  exit 1
fi

# 2) L'ancien nom local a bien disparu : l'image a été retirée de la machine puis tirée du registre
if docker image inspect holocron:v1 >/dev/null 2>&1; then
  echo "L'image holocron:v1 existe encore en local : supprime-la (docker rmi) avant de lancer le conteneur depuis le registre."
  exit 1
fi

# 3) Un conteneur a été créé en nommant l'image avec l'adresse du registre
if ! docker ps -a --format '{{.Image}}' | grep -qx "$REGISTRY_IMAGE"; then
  echo "Aucun conteneur n'a été lancé avec le nom $REGISTRY_IMAGE."
  echo "Lance : docker run $REGISTRY_IMAGE"
  exit 1
fi

echo "L'image est dans le registre local, supprimée en local, puis lancée depuis le registre."
exit 0
