# Bravo !

Tu as exécuté puis planifié une tâche :

1. **Job** : `holonet-ping` a lancé des pods `curl` qui se sont terminés avec succès 3 fois (`completions: 3`).
2. **CronJob** : `holonet-cron` crée un Job toutes les 15 minutes, limité à 30 secondes (`activeDeadlineSeconds`), et garde 10 jobs réussis (`successfulJobsHistoryLimit`). Tu l'as déclenché à la main.

## Points clés à retenir

- Un Deployment maintient des pods en permanence ; un Job lance des pods qui doivent se terminer avec succès. Le `restartPolicy` d'un Job est `Never` ou `OnFailure`, jamais `Always`.
- `completions` : nombre de réussites attendues ; `parallelism` : nombre de pods simultanés (1 par défaut). Les pods terminés ne sont pas supprimés : leurs logs restent lisibles.
- `k create job` et `k create cronjob`, avec `--dry-run=client -o yaml`, génèrent un manifeste à compléter pour les champs sans option (`completions`, `activeDeadlineSeconds`, `successfulJobsHistoryLimit`).
- Un planning cron compte 5 champs : `*/15 * * * *` signifie « toutes les 15 minutes ».
- `activeDeadlineSeconds` (dans `jobTemplate.spec`) limite la durée d'exécution d'un Job ; `startingDeadlineSeconds` (dans le CronJob) limite le délai de démarrage après une échéance manquée.
- `successfulJobsHistoryLimit` (3 par défaut) et `failedJobsHistoryLimit` (1 par défaut) règlent combien de Jobs terminés le CronJob conserve.
- `k create job <nom> --from=cronjob/<cronjob>` teste un CronJob sans attendre l'échéance.

## Pour aller plus loin

- Jobs : https://kubernetes.io/docs/concepts/workloads/controllers/job/
- CronJobs : https://kubernetes.io/docs/concepts/workloads/controllers/cron-jobs/
