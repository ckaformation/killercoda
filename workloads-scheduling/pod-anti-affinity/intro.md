# Pod Anti-Affinity

Bienvenue ! Suite logique du scénario `pod-affinity` : cette fois, on inverse la logique — au lieu de rapprocher deux pods, on les éloigne l'un de l'autre.

## Ce qui est déjà en place

- Un cluster à deux nœuds : `controlplane` et `node01`.
- Un pod déjà en cours d'exécution, `yoda`, explicitement placé sur `node01` (via `nodeName`), avec le label `app=yoda`.
- Un fichier `/root/luke.yaml`, prêt à être complété — le pod `luke` n'existe pas encore.
- Sa définition, `/root/yoda.yaml`, également disponible : elle servira de base à l'étape 2.
- Un raccourci `k` (identique à `kubectl`).

## Ce que tu vas faire

1. Compléter `/root/luke.yaml` avec une **pod anti-affinity** ciblant `app=yoda`, puis lancer `luke` pour la première fois — il doit éviter `node01`, là où se trouve `yoda`.
2. Copier la définition de `yoda` pour créer `yoda-2`, placé cette fois sur `controlplane`, sans toucher au label. Résultat : les deux nœuds portent désormais un pod `app=yoda` — et `luke` n'a alors plus nulle part où se poser.

C'est parti !
