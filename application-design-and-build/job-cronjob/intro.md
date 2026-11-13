# Contexts : un même manifeste, deux namespaces

Bienvenue ! Quand tu tapes `k get pods`, comment `kubectl` sait-il **sur quel cluster**, **avec quelle identité** et **dans quel namespace** travailler ? Il le lit dans ton **kubeconfig** (par défaut `~/.kube/config`), et plus précisément dans le **context courant**.

## Qu'est-ce qu'un context ?

Un context regroupe trois informations :

- un **cluster** : où envoyer les requêtes ;
- un **user** : avec quelle identité ;
- un **namespace** par défaut : celui utilisé quand tu n'ajoutes pas `-n`.

Un kubeconfig peut contenir plusieurs contexts. `kubectl` utilise celui désigné par `current-context`. À l'examen CKA, les énoncés indiquent le context sur lequel travailler : c'est ce geste que tu vas pratiquer ici.

## Ce qui est déjà en place

- Un cluster Kubernetes mono-nœud, prêt à l'emploi.
- Deux namespaces : `hoth` et `endor`.
- Deux contexts ajoutés à ton kubeconfig : `hoth-admin` (namespace `hoth`) et `endor-admin` (namespace `endor`). Ils pointent vers le même cluster avec le même user : seul le namespace par défaut change.
- Tu es déjà positionné sur le context `hoth-admin`.
- Un raccourci `k` (identique à `kubectl`).

## Ce que tu vas faire

1. Identifier le context sur lequel tu te trouves, générer le manifeste d'un pod avec `--dry-run=client`, puis créer le pod.
2. Changer de context et créer le pod à partir du **même fichier**, sans le modifier, pour constater qu'il est créé dans l'autre namespace.

C'est parti !
