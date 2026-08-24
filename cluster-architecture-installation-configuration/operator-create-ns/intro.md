# Opérateur Kubernetes : StatefulSet, CRD et évolution du RBAC

Bienvenue ! Ce scénario prolonge le précédent (`operator-crd-greeting`) : tu vas de nouveau construire un opérateur simplifié, mais cette fois pièce par pièce, et le faire **évoluer** — un cas très réaliste : un opérateur en production gagne des fonctionnalités, et son RBAC doit suivre.

## Ce qui est déjà en place

- Un cluster Kubernetes mono-nœud fonctionnel.
- Le namespace `operators`, où vivra l'opérateur.
- Le `ServiceAccount`, le `ClusterRole` et le `ClusterRoleBinding` de l'opérateur — **mais le `ClusterRole` ne contient pas encore le verbe `patch`**, volontairement : ce sera l'objet de la dernière étape.
- Le manifeste du StatefulSet de l'opérateur, prêt à être examiné puis appliqué, dans `/root/operator/statefulset.yaml`.
- Un raccourci `k` (identique à `kubectl`).

## Ce que tu vas faire

1. Déployer **seulement** le `StatefulSet` de l'opérateur (pas encore la CRD).
2. Déployer la `CustomResourceDefinition` (`NamespaceSet`) que cet opérateur surveille.
3. Déployer une ressource personnalisée (`NamespaceSet`) : l'opérateur doit alors créer 3 namespaces.
4. Faire évoluer l'opérateur pour qu'il labellise aussi ces 3 namespaces — et corriger le `ClusterRole` en conséquence, puisqu'il lui manquera le droit `patch`.

> Comme pour `operator-crd-greeting`, cet "opérateur" est un script shell qui interroge l'API en boucle (pas un vrai binaire compilé avec Operator SDK/Kubebuilder) — une version simplifiée qui illustre le principe, pas une implémentation de production.

C'est parti !
