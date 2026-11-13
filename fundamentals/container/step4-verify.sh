#!/bin/bash
command -v curl >/dev/null 2>&1 || { echo "La commande curl est introuvable."; exit 1; }

# 1) Un conteneur nginx:alpine est en cours d'exécution
ID=""
for id in $(docker ps -q --filter "status=running"); do
  img=$(docker inspect -f '{{.Config.Image}}' "$id" 2>/dev/null)
  if [ "$img" = "nginx:alpine" ]; then
    ID="$id"
    break
  fi
done
if [ -z "$ID" ]; then
  echo "Aucun conteneur en cours d'exécution n'a été lancé avec l'image nginx:alpine."
  echo "Vérifie avec 'docker ps' ; pense à utiliser -d pour le lancer en arrière-plan."
  exit 1
fi

# 2) Son port 80 est publié sur la machine
PORT=$(docker port "$ID" 80/tcp 2>/dev/null | head -1 | awk -F: '{print $NF}')
if [ -z "$PORT" ]; then
  echo "Le port 80 du conteneur n'est pas publié sur la machine. Relance-le avec -p 8080:80."
  exit 1
fi

# 3) Le serveur répond (quelques essais, le temps que nginx démarre)
CODE=""
for i in 1 2 3 4 5 6 7 8 9 10; do
  CODE=$(curl -s -o /dev/null -w "%{http_code}" --max-time 3 "http://localhost:${PORT}")
  [ "$CODE" = "200" ] && break
  sleep 1
done
if [ "$CODE" != "200" ]; then
  echo "Le conteneur tourne, mais http://localhost:${PORT} ne répond pas avec un code 200 (reçu : ${CODE:-aucun})."
  exit 1
fi

echo "Le conteneur nginx:alpine, tiré de Docker Hub, tourne et répond sur le port ${PORT}."
exit 0
