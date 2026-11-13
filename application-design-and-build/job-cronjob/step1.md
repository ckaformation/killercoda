# Étape 1 — Identifier le context courant et créer un pod

## 1. Se placer dans le répertoire de travail

Toutes les commandes du scénario s'exécutent depuis `/root`, là où sera écrit le fichier `pod.yaml`.

`cd ~`{{exec}}

## 2. Sur quel context suis-je ?

`k config current-context`{{exec}}

Tu dois lire `hoth-admin`. Pour voir **tous** les contexts du kubeconfig :

`k config get-contexts`{{exec}}

- l'étoile `*` dans la colonne `CURRENT` marque le context courant ;
- les colonnes `CLUSTER` et `AUTHINFO` donnent le cluster et le user du context ;
- la colonne `NAMESPACE` donne le namespace par défaut de ce context. Quand elle est vide, c'est le namespace `default`.

Tu vois trois contexts : celui d'origine du cluster, et les deux ajoutés pour ce scénario. `hoth-admin` et `endor-admin` ont le même cluster et le même user : **seul le namespace change**.

## 3. Générer le manifeste d'un pod

`k run r2-d2 --image=nginx:alpine --dry-run=client -o yaml > pod.yaml`{{exec}}

- `--dry-run=client` : rien n'est créé dans le cluster, `kubectl` fabrique seulement l'objet ;
- `-o yaml` : cet objet est affiché au format YAML ;
- `> pod.yaml` : la sortie est redirigée dans un fichier plutôt qu'affichée.

N'ajoute pas `-n` à cette commande : ce n'est pas une erreur en soi, mais le namespace serait alors écrit dans le fichier, et le scénario n'aurait plus de sens.

`cat pod.yaml`{{exec}}

Regarde la section `metadata` : tu y trouves le nom `r2-d2` et un label, mais **aucun champ `namespace`**. Ce fichier ne dit pas dans quel namespace créer le pod.

## 4. Créer le pod

`k apply -f pod.yaml`{{exec}}

Comme le manifeste ne précise pas de namespace, `kubectl` utilise celui du context courant. Vérifie-le : la commande suivante n'a pas de `-n`.

`k get pods`{{exec}}

Le pod `r2-d2` est dans la liste (il peut afficher `ContainerCreating` quelques secondes, attends qu'il passe en `Running`). Il est bien dans `hoth`, le namespace de ton context. Dans `endor`, il n'y a rien :

`k get pods -n endor`{{exec}}
