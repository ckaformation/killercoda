# Pod Affinity

Bienvenue ! Après `nodeSelector` et les taints/tolerations, voici un troisième mécanisme de placement : la **pod affinity**, qui ne raisonne plus en termes de nœuds, mais en termes de **pods déjà présents**.

## Ce qui est déjà en place

- Un cluster à deux nœuds : `controlplane` et `node01`.
- Un pod déjà en cours d'exécution, `yoda`, explicitement placé sur `node01` (via `nodeName`).
- Un second fichier, `/root/luke.yaml`, prêt à être complété — le pod `luke` n'existe pas encore.
- Un raccourci `k` (identique à `kubectl`).

## Ce que tu vas faire

1. Compléter `/root/luke.yaml` avec une **pod affinity** ciblant `yoda` (via un `labelSelector`), puis lancer `luke` pour la première fois — il doit se placer sur le même nœud que `yoda`.
2. Supprimer les deux pods, changer le nœud de `yoda` (`node01` → `controlplane`), les recréer, et observer que `luke` suit `yoda` sur son nouveau nœud — sans qu'on ait rien touché à la configuration de `luke` à ce moment-là.

C'est parti !
