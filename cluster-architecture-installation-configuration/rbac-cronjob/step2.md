# Étape 2 — Déclencher le nettoyage manuellement

Maintenant que `leon` a les droits nécessaires, on va déclencher immédiatement une exécution du CronJob, sans attendre sa prochaine planification, avec `kubectl create job --from`.

## 1. Créer un Job à partir du CronJob

`k create job nettoyeur-manuel --from=cronjob/nettoyeur -n ops`{{exec}}

## 2. Suivre son exécution

`watch kubectl get jobs -n ops`{{exec}}

Attends que `nettoyeur-manuel` affiche `1/1` dans la colonne `COMPLETIONS`, puis quitte avec `Ctrl+C`.

## 3. Vérifier que les pods ont bien été supprimés

`k get pods -n ops`{{exec}}

Les pods `pod-a-nettoyer-1`, `pod-a-nettoyer-2` et `pod-a-nettoyer-3` ne doivent plus apparaître : `nettoyeur-manuel` les a supprimés grâce aux droits qu'on vient d'accorder à `leon`.
