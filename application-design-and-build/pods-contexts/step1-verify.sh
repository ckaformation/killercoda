#!/bin/bash
CTX="hoth-admin"
NS="hoth"
POD="r2-d2"
FILE="/root/pod.yaml"

kubectl config get-contexts -o name 2>/dev/null | grep -qx "$CTX" || {
  echo "Le context $CTX n'existe pas encore : la préparation de l'environnement n'est peut-être pas terminée. Patiente quelques secondes et relance la vérification."
  exit 1
}

CURRENT=$(kubectl config current-context 2>/dev/null)
if [ "$CURRENT" != "$CTX" ]; then
  echo "Le context courant est '${CURRENT:-aucun}' : à cette étape tu dois être sur $CTX (voir k config current-context)."
  exit 1
fi

if [ ! -s "$FILE" ]; then
  echo "Le fichier $FILE n'existe pas ou est vide. Génère-le depuis /root avec k run $POD --image=nginx:alpine --dry-run=client -o yaml > pod.yaml."
  exit 1
fi

grep -qE '^kind:[[:space:]]*Pod[[:space:]]*$' "$FILE" || { echo "$FILE ne contient pas un objet de type Pod."; exit 1; }
grep -qE "^[[:space:]]+name:[[:space:]]*$POD[[:space:]]*$" "$FILE" || { echo "Le pod de $FILE ne s'appelle pas $POD."; exit 1; }
grep -qE '^[[:space:]]*-?[[:space:]]*image:[[:space:]]*nginx:alpine[[:space:]]*$' "$FILE" || { echo "L'image de $FILE n'est pas nginx:alpine."; exit 1; }

if grep -qE '^[[:space:]]+namespace:' "$FILE"; then
  echo "$FILE contient un champ namespace : le pod serait toujours créé dans ce namespace, quel que soit le context. Refais le fichier sans passer -n à k run."
  exit 1
fi

IMAGE=$(kubectl -n "$NS" get pod "$POD" -o jsonpath='{.spec.containers[0].image}' 2>/dev/null) || {
  echo "Le pod $POD n'existe pas dans le namespace $NS. Crée-le avec k apply -f pod.yaml (en étant sur le context $CTX)."
  exit 1
}
if [ "$IMAGE" != "nginx:alpine" ]; then
  echo "Le pod $POD utilise l'image '$IMAGE' : l'image attendue est nginx:alpine."
  exit 1
fi

PHASE=""
for i in $(seq 1 30); do
  PHASE=$(kubectl -n "$NS" get pod "$POD" -o jsonpath='{.status.phase}' 2>/dev/null)
  [ "$PHASE" = "Running" ] && break
  sleep 2
done
if [ "$PHASE" != "Running" ]; then
  echo "Le pod $POD n'est pas encore Running (état : ${PHASE:-inconnu}). Attends quelques secondes (k get pods) puis relance la vérification."
  exit 1
fi

echo "Tu es sur le context $CTX, et le pod $POD tourne dans le namespace $NS, créé depuis un pod.yaml sans namespace."
exit 0
