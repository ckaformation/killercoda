# Deployment : ReplicaSet, scaling et mise à jour d'image

Bienvenue ! Dans le scénario précédent, tu as créé un pod « nu » : si on le supprime, il disparaît pour de bon. Pour qu'une application soit maintenue en vie et facile à faire évoluer, on ne crée presque jamais de pods directement : on passe par un **Deployment**.

## Comment ça marche ?

Un Deployment n'est pas un conteneur : c'est la **description d'un état désiré** (quelle image, combien de réplicas...). Il pilote trois niveaux d'objets :

- le **Deployment** que tu crées ;
- un **ReplicaSet**, créé par le Deployment, qui s'assure que le bon nombre de pods existe en permanence ;
- les **pods**, créés par le ReplicaSet.

Un contrôleur compare en continu l'état désiré à l'état réel, et agit pour les faire coïncider : c'est la **boucle de réconciliation**.

## Ce qui est déjà en place

- Un cluster Kubernetes mono-nœud, prêt à l'emploi.
- Un raccourci `k` (identique à `kubectl`).

## Ce que tu vas faire

1. Créer un Deployment de 3 réplicas et observer le ReplicaSet et les pods qu'il engendre, ainsi que les labels qui les relient.
2. Passer le Deployment à 5 réplicas, puis supprimer un pod pour voir le Deployment le remplacer.
3. Mettre à jour l'image du Deployment et observer la création d'un nouveau ReplicaSet.

> Certaines commandes contiennent un `<A_COMPLETER>` : ce n'est pas cliquable, c'est à toi de le remplacer par la bonne valeur avant de l'exécuter.

C'est parti !
