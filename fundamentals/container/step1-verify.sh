#!/bin/bash
IMAGE="holocron:v1"
MSG_FILE="/root/holocron/message.txt"

command -v docker >/dev/null 2>&1 || { echo "La commande docker est introuvable."; exit 1; }

if ! docker image inspect "$IMAGE" >/dev/null 2>&1; then
  echo "L'image $IMAGE n'existe pas. Vérifie le nom et le tag donnés avec -t (docker images)."
  exit 1
fi

OUT=$(timeout 60 docker run --rm "$IMAGE" 2>&1)
if [ "$OUT" != "$(cat "$MSG_FILE")" ]; then
  echo "L'image $IMAGE existe, mais un conteneur lancé à partir d'elle n'affiche pas le contenu de message.txt."
  echo "Vérifie les instructions COPY et CMD de ton Dockerfile, puis reconstruis l'image."
  exit 1
fi

echo "L'image $IMAGE est construite et affiche bien le message."
exit 0
