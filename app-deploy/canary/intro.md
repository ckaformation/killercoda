# Canary : répartir le trafic en jouant sur les réplicas

Bienvenue ! Un déploiement **canary** consiste à faire tourner une nouvelle version à côté de l'actuelle, en ne lui envoyant d'abord qu'une petite partie du trafic. Ici, tu vas doser cette part uniquement avec le nombre de réplicas de chaque version.

## Ce qui est déjà en place

Un cluster Kubernetes mono-nœud, avec dans le namespace `default` :

| Objet | Détail |
|---|---|
| ConfigMap `x-wing-current-page` | un `index.html` qui contient `version : Current` |
| ConfigMap `x-wing-canary-page` | un `index.html` qui contient `version : Canary` |
| Deployment `x-wing-current` | 4 réplicas, labels `app=x-wing`, `track=current`, page `x-wing-current-page` |
| Service `x-wing` | type `NodePort` (port `30080`), selector `app=x-wing` |
| Fichier `/root/x-wing-current.yaml` | le manifeste qui a créé `x-wing-current` |

Le nom `yavin` a été ajouté dans `/etc/hosts` : il pointe vers l'IP du nœud. `curl http://yavin:30080` appelle donc le Service par son NodePort.

Un raccourci `k` (identique à `kubectl`) est aussi disponible.

## Ce que tu vas faire

1. Créer le Deployment `x-wing-canary` (1 réplica) et ramener `x-wing-current` à 3 réplicas : 25 % du trafic va sur la canary.
2. Passer à 2 réplicas de chaque côté : 50 %.
3. Passer à 4 réplicas canary et 0 current : 100 %.

C'est parti !
