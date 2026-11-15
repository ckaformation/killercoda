# Job et CronJob : exécuter et planifier une tâche

Un Deployment relance ses pods en permanence. Un **Job** lance des pods qui doivent **se terminer avec succès**, et un **CronJob** crée un Job à intervalles réguliers.

## Ce qui est déjà en place

- Un cluster Kubernetes mono-nœud.
- Dans le namespace `tatooine` : un Deployment `holonet` (`nginx:alpine`) qui sert une page `index.html` issue d'un ConfigMap, et un Service `holonet` qui l'expose.
- Un raccourci `k` (identique à `kubectl`).

## Ce que tu vas faire

1. Créer un **Job** qui appelle le Service avec `curl` et qui doit se terminer avec succès 3 fois.
2. Planifier la même tâche avec un **CronJob** (toutes les 15 minutes, durée maximale, historique), puis le déclencher à la main.
