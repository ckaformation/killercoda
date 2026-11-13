# nodeSelector et scheduling

Bienvenue ! Ce scénario explore comment Kubernetes choisit sur quel nœud placer un pod : d'abord via `nodeSelector`, puis en observant ce qui se passe quand plus aucun nœud ne correspond, et enfin en désactivant le composant qui prend ces décisions — le `kube-scheduler` lui-même.

## Ce qui est déjà en place

- Un cluster à deux nœuds : `controlplane` et `node01`.
- Les deux nœuds portent déjà un label commun : `side=dark`.
- Deux Deployments, chacun avec 2 réplicas, **sans nodeSelector** pour l'instant : `rebel-fleet` et `imperial-garrison`.
- Un raccourci `k` (identique à `kubectl`).

## Ce que tu vas faire

1. Ajouter un label spécifique à `node01` seul.
2. Configurer `rebel-fleet` pour qu'il puisse se placer sur n'importe quel nœud (via `side=dark`), et `imperial-garrison` pour qu'il soit contraint à `node01` uniquement (via `side=dark` **et** le label spécifique).
3. Retirer `side=dark` de `controlplane`, relancer les deux Deployments, et observer où atterrissent tous les pods.
4. Arrêter le `kube-scheduler`, puis créer un pod avec `nodeName` explicite — et vérifier qu'il démarre quand même.

C'est parti !
