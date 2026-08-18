# RBAC Kubernetes : gérer les permissions de l'utilisateur luke

Bienvenue ! Ce scénario porte sur la gestion des permissions (RBAC — Role-Based Access Control) dans Kubernetes. Tu vas configurer les droits de l'utilisateur **luke** sur un cluster mono-nœud déjà installé.

## Ce qui est déjà en place

- Un cluster Kubernetes fonctionnel (control-plane unique, prêt à recevoir des charges).
- Le namespace **jedi** est déjà créé.
- `kubectl` est configuré, ainsi qu'un raccourci `k` (identique à `kubectl`).

## Ce que tu vas faire

1. Autoriser **luke** à créer et supprimer des pods, deployments et statefulsets, **uniquement** dans le namespace `jedi`.
2. Autoriser **luke** à consulter (droits en lecture seule, `view`) **tous les namespaces existants**, sauf ceux dont le nom commence par `kube-`.

## À propos de "l'utilisateur luke"

Kubernetes n'a pas d'objet natif "User" (contrairement à `ServiceAccount`, qui lui est un vrai objet de l'API). Un utilisateur externe comme `luke` n'existe que par les références qui sont faites à son nom dans les `RoleBinding`/`ClusterRoleBinding` — c'est cette référence qui lui donne (ou non) des droits. Pour vérifier ces droits sans avoir à générer de vrais certificats, on utilise l'usurpation d'identité (`--as=luke`) avec la commande `kubectl auth can-i`, prévue précisément pour ce cas d'usage.

C'est parti !
