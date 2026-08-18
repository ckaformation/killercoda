# Bravo !

Tu viens de configurer les permissions RBAC de l'utilisateur `luke` sur un cluster Kubernetes :

1. **Un `Role` scopé au namespace `jedi`**, autorisant `create` et `delete` sur `pods`, `deployments` et `statefulsets`, lié à luke via un `RoleBinding` dans ce même namespace.
2. **Un `RoleBinding` par namespace** (sauf ceux préfixés `kube-`), liant luke au `ClusterRole` `view` fourni nativement par Kubernetes — pour contourner l'absence de mécanisme d'exclusion par motif dans l'API RBAC.

## Points clés à retenir

- Un `Role`/`RoleBinding` est toujours limité à un namespace ; un `ClusterRole`/`ClusterRoleBinding` s'applique à l'ensemble du cluster.
- Un `ClusterRole` peut être réutilisé dans un `RoleBinding` namespacé (c'est exactement ce qu'on a fait avec `view`) : ça donne les droits du `ClusterRole`, mais seulement dans le namespace du binding.
- Kubernetes n'a pas d'objet "utilisateur" : les droits n'existent que via les références faites dans les bindings, testables avec `kubectl auth can-i --as=<user>` sans avoir besoin de vrais certificats.
- RBAC ne sait pas exprimer une exclusion par motif (« tous les namespaces sauf ceux qui commencent par X ») : ça se résout en itérant sur les namespaces existants, pas au niveau de l'API RBAC elle-même.

## Pour aller plus loin

- Documentation officielle RBAC : https://kubernetes.io/docs/reference/access-authn-authz/rbac/
- `kubectl create role` / `kubectl create rolebinding` : https://kubernetes.io/docs/reference/kubectl/generated/kubectl_create/
- `kubectl auth can-i` : https://kubernetes.io/docs/reference/kubectl/generated/kubectl_auth/kubectl_auth_can-i/
