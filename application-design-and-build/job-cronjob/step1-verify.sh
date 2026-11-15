#!/bin/bash
NS="tatooine"
JOB="holonet-ping"
PHRASE="Que la Force soit avec ce cluster"

job_logs() {
  local out
  out=$(kubectl -n "$NS" logs -l "batch.kubernetes.io/job-name=$1" --tail=-1 2>/dev/null)
  [ -n "$out" ] || out=$(kubectl -n "$NS" logs -l "job-name=$1" --tail=-1 2>/dev/null)
  printf '%s' "$out"
}

kubectl -n "$NS" get job "$JOB" >/dev/null 2>&1 || {
  echo "Le Job $JOB est introuvable dans le namespace $NS : applique ton manifeste avec k apply -f job.yaml -n $NS."
  exit 1
}

IMAGE=$(kubectl -n "$NS" get job "$JOB" -o jsonpath='{.spec.template.spec.containers[0].image}' 2>/dev/null)
case "$IMAGE" in
  curlimages/curl|curlimages/curl:*) ;;
  *) echo "Le Job $JOB devrait utiliser l'image curlimages/curl (obtenu: '$IMAGE')."; exit 1;;
esac

COMPLETIONS=$(kubectl -n "$NS" get job "$JOB" -o jsonpath='{.spec.completions}' 2>/dev/null)
if [ "$COMPLETIONS" != "3" ]; then
  echo "Le Job $JOB devrait avoir completions=3 (obtenu: '${COMPLETIONS:-non défini}'). Supprime-le (k delete job $JOB -n $NS), corrige job.yaml puis relance k apply."
  exit 1
fi

SUCCEEDED=""
for i in $(seq 1 90); do
  SUCCEEDED=$(kubectl -n "$NS" get job "$JOB" -o jsonpath='{.status.succeeded}' 2>/dev/null)
  [ "$SUCCEEDED" = "3" ] && break
  FAILED=$(kubectl -n "$NS" get job "$JOB" -o jsonpath='{.status.conditions[?(@.type=="Failed")].status}' 2>/dev/null)
  if [ "$FAILED" = "True" ]; then
    echo "Le Job $JOB a échoué (trop de pods en erreur). Regarde k logs et k describe job $JOB -n $NS : le curl atteint-il bien le Service ?"
    exit 1
  fi
  sleep 2
done
if [ "$SUCCEEDED" != "3" ]; then
  echo "3 pods devraient s'être terminés avec succès (obtenu: ${SUCCEEDED:-0}). Attends encore (k get job,pods -n $NS) puis relance la vérification."
  exit 1
fi

COUNT=$(job_logs "$JOB" | grep -oF "$PHRASE" | wc -l)
if [ "$COUNT" -lt 3 ]; then
  echo "Les logs des pods du Job devraient contenir 3 fois la page du Service (obtenu: $COUNT). Le curl doit appeler le Service sous la forme <service>.<namespace>."
  exit 1
fi

echo "Le Job $JOB s'est terminé 3 fois et chaque pod a bien récupéré la page du Service."
exit 0
