# Pod Affinity

Bienvenue ! Après `nodeSelector` et les taints/tolerations, voici un troisième mécanisme de placement : la **pod affinity**, qui ne raisonne plus en termes de nœuds, mais en termes de **pods déjà présents**.

## Ce qui est déjà en place

- Un cluster à deux nœuds : `controlplane` et `node01`.
- Deux pods déjà en cours d'exécution :
  - `yoda`, explicitement placé sur `node01` (via `nodeName`) ;
  - `luke`, sans contrainte de placement particulière.
- Leurs définitions YAML sont accessibles pour modification future : `/root/yoda.yaml` et `/root/luke.yaml`.
- Un raccourci `k` (identique à `kubectl`).

## Ce que tu vas faire

1. Modifier `luke` pour qu'il porte une **pod affinity** ciblant `yoda` (via un `labelSelector`), de sorte qu'il se place toujours sur le même nœud que lui.
2. Supprimer les deux pods, changer le nœud de `yoda` (`node01` → `controlplane`), les recréer, et observer que `luke` suit `yoda` sur son nouveau nœud — sans qu'on ait rien touché à la configuration de `luke` à ce moment-là.

C'est parti !
