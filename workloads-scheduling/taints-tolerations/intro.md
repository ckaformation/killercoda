# Taints et Tolerations

Bienvenue ! Après `nodeSelector` (attirer des pods vers des nœuds), place au mécanisme inverse : les **taints**, qui repoussent les pods d'un nœud, sauf ceux qui portent la **toleration** correspondante.

## Ce qui est déjà en place

- Un cluster à deux nœuds : `controlplane` et `node01`, tous deux sans taint pour l'instant.
- Deux Deployments, chacun avec 2 réplicas : `millennium-falcon` et `x-wing-squadron`.
- Un raccourci `k` (identique à `kubectl`).

## Ce que tu vas faire

1. Ajouter un taint `NoSchedule` sur `controlplane`, et observer son effet sur les deux Deployments.
2. Modifier **seulement** `millennium-falcon` pour qu'il tolère ce taint et puisse continuer à se poser sur `controlplane`.
3. Ajouter un **second** taint, `NoExecute` cette fois, toujours sur `controlplane` — et observer une différence importante avec `NoSchedule`.
4. Modifier de nouveau `millennium-falcon` pour tolérer aussi ce second taint.

`x-wing-squadron` ne sera jamais modifié : il sert de référence, pour bien voir ce qui se passe **sans** toleration.

C'est parti !
