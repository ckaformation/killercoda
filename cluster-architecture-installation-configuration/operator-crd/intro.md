# Opérateur Kubernetes : installation et CRD

Bienvenue ! Ce scénario porte sur le **pattern opérateur** : un contrôleur qui surveille des ressources personnalisées (CRD/CR) et réagit en créant/gérant d'autres objets Kubernetes en conséquence.

## Ce qui est déjà en place

- Un cluster Kubernetes mono-nœud fonctionnel.
- Trois namespaces : **luke**, **ben** et **leia**.
- Un raccourci `k` (identique à `kubectl`).
- Les manifestes de l'opérateur, prêts à être examinés puis appliqués, dans `/root/operator/operator.yaml`.

## Ce que tu vas faire

1. **Installer un opérateur** volontairement simple (il ne fait qu'une seule chose : créer une ConfigMap), scopé pour n'agir que sur les namespaces `luke`, `ben` et `leia` — pas sur le reste du cluster.
2. **Créer une CRD** (CustomResourceDefinition) assez simpliste, puis une ressource personnalisée basée dessus, et observer l'opérateur la "réconcilier" en créant la ConfigMap correspondante.

> Note honnête : cet opérateur n'est pas construit avec un framework comme Operator SDK ou Kubebuilder (ça demanderait de compiler et publier une image, impossible dans cet environnement). C'est un script shell qui interroge l'API Kubernetes en boucle — une version simplifiée, mais qui illustre fidèlement le principe : surveiller une ressource personnalisée, et réagir en conséquence.

C'est parti !
