# Rollouts : stratégie, pause/reprise et rollback

Bienvenue ! Un `Deployment` ne se contente pas de créer des pods : il pilote la façon dont une nouvelle version remplace l'ancienne (le **rollout**), garde un historique des versions déployées (les **révisions**) et permet de revenir en arrière. Dans ce scénario, tu manipules ces trois aspects avec `kubectl rollout`.

## Ce qui est déjà en place

Un cluster Kubernetes mono-nœud, avec trois `Deployments` dans le namespace `default`, tous basés sur l'image `nginx:alpine` et portant une variable d'environnement `APP_RELEASE` :

| Deployment | Réplicas | Situation |
|---|---|---|
| `millennium-falcon` | 2 | Déployé avec la stratégie `Recreate` |
| `death-star` | 1 | Son rollout a été mis en pause |
| `tie-fighter` | 1 | Stratégie `Recreate`, quatre révisions déjà déployées, dont la dernière pose problème |

Un raccourci `k` (identique à `kubectl`) est aussi disponible.

> La préparation de l'environnement prend un peu de temps (elle doit laisser le temps à l'un des Deployments de tomber en erreur). La première commande de l'étape 1 t'invite à patienter jusqu'à ce que tout soit prêt.

## Ce que tu vas faire

1. Dans un seul `kubectl edit`, passer `millennium-falcon` en `RollingUpdate` (`maxSurge: 1`, `maxUnavailable: 0`) et changer la valeur de `APP_RELEASE`, puis suivre le rollout.
2. Comprendre pourquoi une modification de `death-star` n'est jamais déployée, et débloquer la situation.
3. Constater que `tie-fighter` a un pod en `CrashLoopBackOff`, observer ses révisions et revenir à la révision 2.

> Certaines commandes contiennent un `<A_COMPLETER>` : ce n'est pas cliquable, c'est à toi de le remplacer par la bonne valeur avant de l'exécuter.

C'est parti !
