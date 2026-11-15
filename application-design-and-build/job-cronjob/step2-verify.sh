#!/bin/bash
NS="tatooine"
CJ="holonet-cron"
FIRST_JOB="holonet-ping"
PHRASE="Que la Force soit avec ce cluster"

kubectl -n "$NS" get cronjob "$CJ" >/dev/null 2>&1 || {
  echo "Le CronJob $CJ est introuvable dans le namespace $NS : applique ton manifeste avec k apply -f cronjob.yaml -n $NS."
  exit 1
}

SCHEDULE=$(kubectl -n "$NS" get cronjob "$CJ" -o jsonpath='{.spec.schedule}' 2>/dev/null)
case "$SCHEDULE" in
  "*/15 * * * *"|"0,15,30,45 * * * *") ;;
  *) echo "Le planning du CronJob devrait être '*/15 * * * *', toutes les 15 minutes (obtenu: '$SCHEDULE')."; exit 1;;
esac

IMAGE=$(kubectl -n "$NS" get cronjob "$CJ" -o jsonpath='{.spec.jobTemplate.spec.template.spec.containers[0].image}' 2>/dev/null)
case "$IMAGE" in
  curlimages/curl|curlimages/curl:*) ;;
  *) echo "Le CronJob devrait utiliser l'image curlimages/curl (obtenu: '$IMAGE')."; exit 1;;
esac

DEADLINE=$(kubectl -n "$NS" get cronjob "$CJ" -o jsonpath='{.spec.jobTemplate.spec.activeDeadlineSeconds}' 2>/dev/null)
if [ "$DEADLINE" != "30" ]; then
  echo "spec.jobTemplate.spec.activeDeadlineSeconds devrait valoir 30 (obtenu: '${DEADLINE:-non défini}')."
  exit 1
fi

HISTORY=$(kubectl -n "$NS" get cronjob "$CJ" -o jsonpath='{.spec.successfulJobsHistoryLimit}' 2>/dev/null)
if [ "$HISTORY" != "10" ]; then
  echo "spec.successfulJobsHistoryLimit devrait valoir 10 (obtenu: '${HISTORY:-non défini}')."
  exit 1
fi

# Un Job issu du CronJob (planifie ou manuel) : different du Job de l'etape 1
# et porte la limite de duree de 30 s heritee du jobTemplate.
list_jobs() {
  kubectl -n "$NS" get jobs -o jsonpath='{range .items[*]}{.metadata.name}|{.status.succeeded}|{.spec.activeDeadlineSeconds}{"\n"}{end}' 2>/dev/null
}

CANDIDATES=$(list_jobs | awk -F'|' -v skip="$FIRST_JOB" '$1!="" && $1!=skip && $3+0==30 {print $1}')
if [ -z "$CANDIDATES" ]; then
  echo "Aucun Job issu du CronJob n'a été trouvé : déclenche-le avec k create job holonet-cron-manual --from=cronjob/$CJ -n $NS."
  exit 1
fi

DONE_JOB=""
for i in $(seq 1 60); do
  DONE_JOB=$(list_jobs | awk -F'|' -v skip="$FIRST_JOB" '$1!="" && $1!=skip && $2+0>=1 && $3+0==30 {print $1; exit}')
  [ -n "$DONE_JOB" ] && break
  sleep 2
done
if [ -z "$DONE_JOB" ]; then
  echo "Un Job issu du CronJob devrait s'être terminé avec succès (obtenu: aucun pour l'instant). Attends encore (k get jobs -n $NS) et consulte ses logs s'il reste en échec."
  exit 1
fi

if ! kubectl -n "$NS" logs "job/$DONE_JOB" 2>/dev/null | grep -qF "$PHRASE"; then
  echo "Les logs du Job $DONE_JOB devraient contenir la page du Service (obtenu: autre chose). Vérifie la commande curl du CronJob."
  exit 1
fi

echo "Le CronJob $CJ est correct (toutes les 15 minutes, 30 s maximum, 10 jobs réussis conservés) et le Job $DONE_JOB l'a exécuté avec succès."
exit 0
