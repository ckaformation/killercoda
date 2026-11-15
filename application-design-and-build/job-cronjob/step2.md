# Étape 2 — Planifier la tâche avec un CronJob

Le CronJob doit faire la même chose que ton Job, avec trois exigences :

- se lancer **toutes les 15 minutes** ;
- se terminer **après 30 secondes maximum** ;
- garder **10 jobs réussis** dans son historique.

## 1. Générer le manifeste du CronJob

```
k create cronjob holonet-cron --image=curlimages/curl --schedule="*/15 * * * *" --dry-run=client -o yaml -- curl holonet.tatooine > cronjob.yaml
```{{exec}}

Le planning `*/15 * * * *` compte cinq champs (minute, heure, jour du mois, mois, jour de la semaine) : `*/15` dans celui des minutes signifie « toutes les 15 minutes ».

## 2. Ajouter la durée maximale et l'historique

Ces deux réglages n'ont pas d'option en ligne de commande, et ils ne se placent pas au même endroit :

- `successfulJobsHistoryLimit` : nombre de Jobs réussis conservés (3 par défaut), dans le `spec` du CronJob ;
- `activeDeadlineSeconds` : durée maximale d'exécution d'un Job, dans le `spec` du `jobTemplate`.

Pour retrouver l'emplacement d'un champ :

`k explain cronjob.spec.jobTemplate.spec.activeDeadlineSeconds`{{exec}}

`vi cronjob.yaml`{{exec}}

Ajoute les deux lignes marquées, en respectant l'indentation :

```yaml
spec:
  successfulJobsHistoryLimit: 10   # à ajouter
  jobTemplate:
    spec:
      activeDeadlineSeconds: 30    # à ajouter
      template:
```

Sauvegarde et quitte : `Échap`, puis `:wq`, puis `Entrée`.

`activeDeadlineSeconds` limite la durée d'**exécution** d'un Job. Ne le confonds pas avec `startingDeadlineSeconds`, un champ du CronJob : c'est le délai pour **démarrer** un Job dont l'échéance a été manquée.

## 3. Créer le CronJob

`k apply -f cronjob.yaml -n tatooine`{{exec}}

`k get cronjob -n tatooine`{{exec}}

La prochaine échéance peut être dans plusieurs minutes : tu vas le déclencher toi-même.

## 4. Le déclencher à la main

`k create job holonet-cron-manual --from=cronjob/holonet-cron -n tatooine`{{exec}}

Cette commande crée tout de suite un Job à partir du `jobTemplate` du CronJob, sans attendre le planning.

`k wait --for=condition=complete job/holonet-cron-manual -n tatooine --timeout=120s`{{exec}}

`k logs job/holonet-cron-manual -n tatooine`{{exec}}

Le Job a repris les réglages du `jobTemplate` :

`k get job holonet-cron-manual -n tatooine -o jsonpath='{.spec.activeDeadlineSeconds}{"\n"}'`{{exec}}

Tu lis `30`.
