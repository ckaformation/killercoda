# Workloads : Pod, Deployment, StatefulSet et rollouts

Bienvenue dans le chapitre Workloads & Scheduling ! Ce scénario couvre les trois principaux objets de charge applicative (Pod, Deployment, StatefulSet), la mécanique des révisions et des rollbacks, et une subtilité souvent mal comprise : la stratégie de mise à jour `OnDelete` d'un StatefulSet.

## Ce qui est déjà en place

- Un cluster Kubernetes mono-nœud fonctionnel.
- Un raccourci `k` (identique à `kubectl`).

## Ce que tu vas faire

1. Déployer un **Pod nu** — ni Deployment, ni StatefulSet, juste un Pod.
2. Déployer le même genre de charge via un **Deployment**, puis le scaler avec `kubectl edit`.
3. Modifier deux fois le Deployment de façon à incrémenter son numéro de révision, puis revenir en arrière de deux révisions avec `kubectl rollout undo`.
4. Déployer un **StatefulSet** basé sur `redis:7-alpine`, avec la stratégie `updateStrategy: OnDelete`, et modifier son CPU request.
5. Faire un `kubectl rollout undo` sur ce StatefulSet.

> Petit rappel utile pour la suite : `kubectl rollout undo --to-revision=N` ne fait pas "réapparaître" le numéro de révision N — Kubernetes crée toujours un **nouveau** numéro de révision (le plus haut), avec le **contenu** de l'ancienne. On y reviendra concrètement à l'étape 3.

C'est parti !
