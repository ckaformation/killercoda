# Étape 2 — Changer de context et recréer le même pod

Tu vas maintenant utiliser **exactement le même fichier** `pod.yaml`, sans le modifier, et sans taper `-n`.

## 1. Vérifier que le fichier est toujours là

`ls pod.yaml`{{exec}}

Si la commande répond « No such file or directory », tu n'es plus dans `/root` : fais d'abord un `cd ~`.

## 2. Changer de context

`k config use-context endor-admin`{{exec}}

`k config current-context`{{exec}}

`k config get-contexts`{{exec}}

L'étoile `*` est passée sur `endor-admin`. `use-context` a modifié le champ `current-context` de ton kubeconfig : toutes les commandes `kubectl` suivantes s'adresseront maintenant au namespace `endor`.

## 3. Constater que le namespace est vide

`k get pods`{{exec}}

Tu obtiens `No resources found in endor namespace.` : le pod `r2-d2` créé à l'étape 1 est dans `hoth`, tu ne le vois plus car ton context pointe désormais ailleurs.

## 4. Créer le pod avec le même fichier

`k apply -f pod.yaml`{{exec}}

Tu lis `pod/r2-d2 created` : pour Kubernetes, c'est un nouveau pod, car un nom n'est unique qu'**au sein d'un namespace**.

`k get pods`{{exec}}

Le pod `r2-d2` apparaît, cette fois dans `endor`. Même fichier, même commande : seul le context a changé.

## 5. Les deux pods coexistent

`k get pods -A | grep -E 'NAMESPACE|r2-d2'`{{exec}}

Tu vois deux pods qui portent le même nom `r2-d2`, l'un dans `hoth`, l'autre dans `endor`.

## 6. Le flag `-n` : une exception ponctuelle

Tu es toujours sur le context `endor-admin`. Pour regarder `hoth` **sans changer de context**, il suffit d'ajouter `-n` à une commande :

`k get pods -n hoth`{{exec}}

Le flag `-n` s'applique à cette seule commande et prend le pas sur le namespace du context. Vérifie que le context n'a pas bougé :

`k config current-context`{{exec}}
