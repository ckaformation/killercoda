# Bravo !

Tu as manipulé les trois facettes d'un rollout :

1. **La stratégie** : `millennium-falcon` est passé de `Recreate` à `RollingUpdate` avec `maxSurge: 1` et `maxUnavailable: 0`, puis a été mis à jour sans jamais descendre sous 2 pods disponibles.
2. **La pause et la reprise** : une modification faite sur `death-star` pendant que son rollout était en pause n'a été déployée qu'après `kubectl rollout resume`.
3. **L'historique et le rollback** : `tie-fighter` a été restauré à la révision 2 avec `kubectl rollout undo --to-revision=2`, ce qui a éliminé le pod en `CrashLoopBackOff`.

## Ce qu'il faut retenir

- Seule une modification du **pod template** (image, variables d'environnement, commande...) crée une nouvelle révision. Le scaling et le changement de stratégie n'en créent pas.
- `maxSurge` fixe combien de pods peuvent exister **en plus** du nombre souhaité pendant une mise à jour ; `maxUnavailable` fixe combien peuvent manquer.
- Avec `Recreate`, il n'y a aucune coexistence ancienne/nouvelle version, mais le service est interrompu pendant la mise à jour.
- Un rollout en pause enregistre les modifications sans les déployer : on peut regrouper plusieurs changements en un seul rollout.
- `kubectl rollout undo` restaure le **contenu** d'une révision mais l'enregistre sous un **nouveau** numéro.
- `kubectl rollout status` attend la fin du rollout ; il renvoie un code de sortie non nul si le Deployment dépasse son délai de progression, ce qui le rend utilisable dans un script.
- Pendant le déploiement défectueux de `tie-fighter`, les anciens pods sont restés en service : avec `maxUnavailable` à 0 (ou à une valeur arrondie à 0), un rollout qui échoue ne dégrade pas la capacité existante.

## Pour aller plus loin

- Documentation officielle des Deployments : https://kubernetes.io/docs/concepts/workloads/controllers/deployment/
