#!/bin/bash
IMAGE="holocron:v1"
MSG="$(cat /root/holocron/message.txt)"

docker image inspect "$IMAGE" >/dev/null 2>&1 || { echo "L'image $IMAGE n'existe plus. Reprends l'étape 1."; exit 1; }

# 1) Un conteneur terminé avec le code 0, dont les logs contiennent le message
FOUND=0
for id in $(docker ps -a -q --filter "ancestor=$IMAGE" --filter "status=exited"); do
  code=$(docker inspect -f '{{.State.ExitCode}}' "$id" 2>/dev/null)
  if [ "$code" = "0" ] && docker logs "$id" 2>&1 | grep -qF "$MSG"; then
    FOUND=1
    break
  fi
done
if [ "$FOUND" != "1" ]; then
  echo "Aucun conteneur terminé (Exited (0)) issu de $IMAGE n'a affiché le message."
  echo "Lance 'docker run $IMAGE' puis regarde 'docker ps -a'."
  exit 1
fi

# 2) Un conteneur toujours en cours d'exécution, issu de la même image
RUNNING=$(docker ps -q --filter "ancestor=$IMAGE" --filter "status=running")
if [ -z "$RUNNING" ]; then
  echo "Aucun conteneur issu de $IMAGE n'est en cours d'exécution."
  echo "Lance-en un en arrière-plan : docker run -d --name <nom> $IMAGE sleep 3600"
  exit 1
fi

echo "Un conteneur terminé et un conteneur en cours d'exécution sont bien issus de $IMAGE."
exit 0
