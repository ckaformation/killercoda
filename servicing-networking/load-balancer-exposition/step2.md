# Étape 2 — Ajouter un HorizontalPodAutoscaler

## 1. Créer le HPA

`kubectl autoscale deployment holonet -n holonet --min=2 --max=4 --cpu-percent=50`{{exec}}

## 2. Vérifier

`k get hpa holonet -n holonet`{{exec}}

La colonne `TARGETS` doit afficher un pourcentage réel (par exemple `1%/50%`), pas `<unknown>/50%` — c'est `metrics-server`, déjà en place, qui rend ça possible.

`k describe hpa holonet -n holonet`{{exec}}

## 3. Comprendre ce qui a été mis en place

- `minReplicas: 2` : le `Deployment` a déjà 2 réplicas — le HPA ne descendra jamais en dessous.
- `maxReplicas: 4` : en cas de charge, il pourra monter jusqu'à 4.
- Cible : `50%` d'utilisation CPU moyenne, calculée par rapport à la demande CPU (`requests.cpu: 100m`) définie sur chaque pod de `holonet`.

Avec une charge CPU actuelle proche de 0%, il n'y a ici aucune raison pour le HPA de déclencher un scaling — c'est normal, l'objectif de cette étape est de vérifier que le HPA est correctement configuré et opérationnel, pas de générer artificiellement de la charge.
