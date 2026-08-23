# Étape 2 — Déclencher le nettoyage manuellement

Maintenant que `leon` a les droits nécessaires, on va déclencher une exécution du CronJob. Comme il est suspendu (`spec.suspend: true`), sa planification ne se déclenchera jamais toute seule : `kubectl create job --from` est le moyen de lancer une exécution ponctuelle à partir de son modèle (`jobTemplate`), sans avoir à le désuspendre.

## 1. Créer un Job à partir du CronJob

`k create job nettoyeur-manuel --from=cronjob/nettoyeur -n ops`{{exec}}

## 2. Suivre son exécution

`watch kubectl get jobs -n ops`{{exec}}

Attends que `nettoyeur-manuel` affiche `1/1` dans la colonne `COMPLETIONS`, puis quitte avec `Ctrl+C`.

## 3. Vérifier que les pods ont bien été supprimés

`k get pods -n ops`{{exec}}

Les pods `pod-a-nettoyer-1`, `pod-a-nettoyer-2` et `pod-a-nettoyer-3` ne doivent plus apparaître : `nettoyeur-manuel` les a supprimés grâce aux droits qu'on vient d'accorder à `leon`.
