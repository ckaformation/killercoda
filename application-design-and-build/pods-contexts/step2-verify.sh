#!/bin/bash
CTX="endor-admin"
NS="endor"
OTHER_NS="hoth"
POD="r2-d2"
FILE="/root/pod.yaml"

CURRENT=$(kubectl config current-context 2>/dev/null)
if [ "$CURRENT" != "$CTX" ]; then
  echo "Le context courant est '${CURRENT:-aucun}' : à cette étape tu dois être sur $CTX (k config use-context $CTX)."
  exit 1
fi

if [ ! -s "$FILE" ]; then
  echo "Le fichier $FILE a disparu : il doit rester celui de l'étape 1."
  exit 1
fi
if grep -qE '^[[:space:]]+namespace:' "$FILE"; then
  echo "$FILE contient un champ namespace : le fichier ne doit pas être modifié, c'est le context qui choisit le namespace."
  exit 1
fi

IMAGE=$(kubectl -n "$NS" get pod "$POD" -o jsonpath='{.spec.containers[0].image}' 2>/dev/null) || {
  echo "Le pod $POD n'existe pas dans le namespace $NS. Crée-le avec k apply -f pod.yaml, en étant sur le context $CTX."
  exit 1
}
if [ "$IMAGE" != "nginx:alpine" ]; then
  echo "Le pod $POD du namespace $NS utilise l'image '$IMAGE' : l'image attendue est nginx:alpine."
  exit 1
fi

kubectl -n "$OTHER_NS" get pod "$POD" >/dev/null 2>&1 || {
  echo "Le pod $POD du namespace $OTHER_NS (étape 1) n'existe plus : il devait rester en place pour que les deux pods coexistent."
  exit 1
}

PHASE=""
for i in $(seq 1 30); do
  PHASE=$(kubectl -n "$NS" get pod "$POD" -o jsonpath='{.status.phase}' 2>/dev/null)
  [ "$PHASE" = "Running" ] && break
  sleep 2
done
if [ "$PHASE" != "Running" ]; then
  echo "Le pod $POD du namespace $NS n'est pas encore Running (état : ${PHASE:-inconnu}). Attends quelques secondes (k get pods) puis relance la vérification."
  exit 1
fi

echo "Tu es sur le context $CTX : le même pod.yaml a créé le pod $POD dans $NS, et celui de $OTHER_NS est toujours là."
exit 0
