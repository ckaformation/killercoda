#!/bin/bash
DOCKERFILE="/root/r2d2/Dockerfile"
IMAGE="localhost/r2d2:v1"
CTR="r2d2"

command -v podman >/dev/null 2>&1 || { echo "❌ La commande podman est introuvable : lance /root/wait-for-prep.sh."; exit 1; }

if [ ! -f "$DOCKERFILE" ]; then
  echo "❌ Le fichier $DOCKERFILE est introuvable."
  exit 1
fi

if ! grep -iqE '^[[:space:]]*FROM[[:space:]]+(docker\.io/)?(library/)?bash([:@][^[:space:]]+)?([[:space:]]|$)' "$DOCKERFILE"; then
  echo "❌ Le Dockerfile devrait partir de l'image bash (obtenu : '$(grep -iE '^[[:space:]]*FROM' "$DOCKERFILE" | head -n1)')."
  exit 1
fi

IMG_ID=$(podman image inspect --format '{{.Id}}' "$IMAGE" 2>/dev/null)
if [ -z "$IMG_ID" ]; then
  echo "❌ L'image r2d2:v1 n'existe pas. Lance : podman build -t r2d2:v1 . (depuis /root/r2d2)."
  exit 1
fi

CMD=$(podman image inspect --format '{{.Config.Entrypoint}} {{.Config.Cmd}}' "$IMAGE" 2>/dev/null)
if ! echo "$CMD" | grep -q "ping" || ! echo "$CMD" | grep -q "127\.0\.0\.1"; then
  echo "❌ L'image r2d2:v1 devrait lancer ping 127.0.0.1 au démarrage (obtenu : $CMD). Corrige le CMD puis reconstruis l'image."
  exit 1
fi

if ! podman container exists "$CTR" 2>/dev/null; then
  echo "❌ Aucun container nommé $CTR. Lance : podman run -d --name r2d2 --cap-add NET_RAW r2d2:v1"
  exit 1
fi

CTR_IMG=$(podman inspect --format '{{.Image}}' "$CTR" 2>/dev/null)
if [ "$CTR_IMG" != "$IMG_ID" ]; then
  echo "❌ Le container $CTR ne tourne pas sur l'image r2d2:v1 actuelle. Supprime-le (podman rm -f r2d2) et relance-le."
  exit 1
fi

STATE=$(podman inspect --format '{{.State.Status}}' "$CTR" 2>/dev/null)
if [ "$STATE" != "running" ]; then
  if podman logs "$CTR" 2>&1 | grep -q "permission denied"; then
    echo "❌ Le container $CTR s'est arrêté : ping n'a pas la capability NET_RAW. Supprime-le (podman rm -f r2d2) et relance-le avec --cap-add NET_RAW."
  else
    echo "❌ Le container $CTR devrait être en cours d'exécution (obtenu : '$STATE'). Regarde podman logs r2d2."
  fi
  exit 1
fi

if ! podman logs "$CTR" 2>&1 | grep -q "bytes from 127\.0\.0\.1"; then
  echo "❌ Les logs de $CTR ne montrent pas encore de réponse de 127.0.0.1. Attends quelques secondes et relance la vérification."
  exit 1
fi

echo "✅ L'image r2d2:v1 est construite et le container r2d2 ping 127.0.0.1."
exit 0
