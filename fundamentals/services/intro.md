# Service : pourquoi, ClusterIP, DNS et NodePort

Bienvenue ! Les pods sont éphémères : ils naissent, meurent et sont remplacés, et leur adresse IP avec eux. Comment une application peut-elle alors en joindre une autre de façon fiable ? C'est le rôle du **Service**. Dans ce scénario, tu vas le découvrir en partant du problème.

## Ce qui est déjà en place

- Un cluster Kubernetes à deux nœuds : `controlplane` et `node01`.
- Un raccourci `k` (identique à `kubectl`) sur `controlplane`.
- Un `Deployment` nommé `echo-base`, de **3 réplicas**, dans le namespace `default`. Son image, `wbitt/network-multitool`, embarque un serveur web (nginx, sur le port 80) **et** les outils réseau usuels, dont `curl`. La page qu'il sert indique quel pod répond.

## Ce que tu vas faire

1. Appeler l'application avec `curl` sur l'IP d'un pod, et comprendre pourquoi ce n'est pas une solution durable.
2. Exposer le Deployment avec un Service (`k expose`), et l'appeler par sa `CLUSTER-IP`.
3. Supprimer un pod et constater que le Service continue de répondre.
4. Appeler le Service **par son nom** depuis un pod, et comprendre la nomenclature DNS de Kubernetes.
5. Transformer le Service en `NodePort` pour l'atteindre depuis les nodes.

> Certaines commandes contiennent un `<A_COMPLETER>` : ce n'est pas cliquable, c'est à toi de le remplacer par la bonne valeur avant de l'exécuter.

C'est parti !
