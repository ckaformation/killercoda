# Bravo !

Tu viens de construire un opérateur Kubernetes pièce par pièce, et de le faire évoluer :

1. **StatefulSet** de l'opérateur, déployé seul — sans CRD, il ne fait rien.
2. **CRD** `NamespaceSet` (cluster-scoped, puisqu'elle pilote des `Namespace`, eux-mêmes cluster-scoped).
3. **Ressource personnalisée** : l'opérateur réagit en créant les 3 namespaces demandés.
4. **Évolution** : nouvelle fonctionnalité (labellisation) ajoutée au script de l'opérateur, échec `Forbidden` par manque du verbe `patch`, diagnostic via les logs et `kubectl auth can-i`, puis correction du `ClusterRole`.

## Points clés à retenir

- Un opérateur sans sa CRD ne fait rien (il attend), et une CRD sans opérateur ne fait rien non plus (personne ne réagit à ses instances) — les deux sont indépendants à déployer, mais interdépendants pour fonctionner.
- Une ressource cluster-scoped (comme `Namespace`) ne peut être gouvernée que par un `ClusterRole` lié via un `ClusterRoleBinding` — un `RoleBinding` namespacé n'a pas de prise dessus, quel que soit le namespace choisi.
- `kubectl label` (comme `kubectl annotate` ou `kubectl patch`) envoie une requête **PATCH** à l'API : le RBAC nécessaire est le verbe `patch`, pas un verbe "label" dédié qui n'existe pas.
- Faire évoluer les capacités d'un opérateur implique presque toujours de faire évoluer son RBAC en parallèle — les oublier l'un sans l'autre est une source d'incidents très courante en production.

## Pour aller plus loin

- CustomResourceDefinition : https://kubernetes.io/docs/tasks/extend-kubernetes/custom-resources/custom-resource-definitions/
- RBAC : https://kubernetes.io/docs/reference/access-authn-authz/rbac/
- StatefulSets : https://kubernetes.io/docs/concepts/workloads/controllers/statefulset/
