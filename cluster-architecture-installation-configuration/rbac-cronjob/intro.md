# RBAC Kubernetes : réparer un CronJob de nettoyage

Bienvenue ! Ce scénario porte à nouveau sur RBAC, cette fois appliqué à un **ServiceAccount** utilisé par un **CronJob** — un cas très courant en production (jobs de nettoyage, de sauvegarde, de rotation de certificats, etc., qui tournent avec des droits dédiés et minimaux).

## Ce qui est déjà en place

- Le namespace **ops**.
- Un **ServiceAccount** nommé **leon**, dans `ops`.
- Un **CronJob** nommé **nettoyeur**, dans `ops`, planifié toutes les minutes, qui utilise le ServiceAccount `leon`. Son rôle : supprimer les pods à l'état `Completed` dans le namespace `ops`.
- **Trois pods** (`pod-a-nettoyer-1/2/3`), basés sur l'image `busybox`, qui se terminent immédiatement (`echo done`) et passent donc rapidement à l'état `Completed` — ce sont eux que le CronJob est censé supprimer.
- Un raccourci `k` (identique à `kubectl`).

## Le problème

Le CronJob `nettoyeur` échoue : le ServiceAccount `leon` n'a **aucun droit RBAC**. Ton objectif :

1. Diagnostiquer le problème, donner à `leon` les droits nécessaires, et vérifier que le nettoyage automatique fonctionne.
2. Cloner `leon` en un second ServiceAccount, `leon-2`, avec `automountServiceAccountToken: false`.
3. Étendre le `RoleBinding` existant pour que `leon-2` hérite des mêmes droits que `leon`.

C'est parti !
