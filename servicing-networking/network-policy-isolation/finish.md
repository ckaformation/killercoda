# Bravo !

Tu viens de construire une isolation réseau progressive, à base de `NetworkPolicy` :

1. **Deny by default** : un `podSelector` vide et aucune règle `ingress`, dans chacun des deux namespaces — bloque tout, y compris le trafic intra-namespace.
2. **Autorisation ciblée intra-namespace** : `luke` → `obi-wan`, via un simple `podSelector` dans `from` (implicitement limité au namespace de la policy).
3. **Autorisation ciblée inter-namespaces** : `luke` (et lui seul) → `leia`, via `namespaceSelector` **et** `podSelector` combinés dans le même élément de la liste `from`.

## Points clés à retenir

- Sans `NetworkPolicy`, Kubernetes autorise tout le trafic entre tous les pods, de tous les namespaces — l'isolation n'est jamais activée par défaut.
- Les `NetworkPolicy` ne fonctionnent que si le CNI du cluster les implémente. Tous les CNI ne le font pas : le vérifier fait partie du travail avant de compter dessus en production.
- Un `podSelector` seul dans `from` (sans `namespaceSelector`) désigne des pods du **même namespace** que la `NetworkPolicy`.
- Dans une liste `from`, deux sélecteurs au **même niveau** (même élément) se combinent en **ET** ; deux éléments **séparés** de la liste se combinent en **OU**. Cette nuance d'indentation change radicalement la portée réelle d'une règle — une source d'erreur silencieuse très fréquente.
- `kubernetes.io/metadata.name` est posé automatiquement par Kubernetes sur chaque namespace : un moyen fiable de cibler un namespace par son nom dans un `namespaceSelector`, sans avoir à le labelliser soi-même.

## Pour aller plus loin

- Network Policies : https://kubernetes.io/docs/concepts/services-networking/network-policies/
