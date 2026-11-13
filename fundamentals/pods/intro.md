# Pod : les fondamentaux, du kubectl au runtime

Bienvenue ! Le **Pod** est la plus petite unité que Kubernetes sait déployer. Presque tout le reste (Deployment, StatefulSet, Job...) n'est qu'une façon de créer et de gérer des pods. Dans ce scénario, tu vas suivre la vie d'un pod de bout en bout : de la commande `kubectl` jusqu'au container qui tourne sur un node.

## Qu'est-ce qu'un Pod ?

- Un pod enveloppe **un ou plusieurs containers** qui partagent le même réseau (une seule adresse IP, les mêmes ports) et, si on le souhaite, des volumes.
- Le **scheduler** choisit un node pour le pod. Une fois placé, le pod reste sur ce node.
- Le **kubelet** de ce node lance et surveille les containers du pod, en s'appuyant sur le runtime de containers (ici **containerd**).
- Un pod est **éphémère** : si on le supprime, il ne revient pas tout seul, sauf si un contrôleur (comme un Deployment) est chargé de le recréer.

## Ce qui est déjà en place

- Un cluster Kubernetes à deux nœuds : `controlplane` et `node01`.
- Un raccourci `k` (identique à `kubectl`) sur `controlplane`.
- L'outil `crictl` sur `node01`, pour interroger directement containerd.

## Ce que tu vas faire

1. Créer un pod avec `k run`, puis l'inspecter avec `k describe` et `k logs`.
2. Constater sur quel node il a été placé et pourquoi, puis te connecter à ce node en `ssh` pour retrouver ses containers avec `crictl`.
3. Supprimer le container avec `crictl rm -f` et observer que le kubelet le recrée, puis supprimer le pod avec `k delete pod` et observer qu'il ne revient pas.

> Certaines commandes contiennent un `<A_COMPLETER>` : ce n'est pas cliquable, c'est à toi de le remplacer par la bonne valeur avant de l'exécuter.

C'est parti !
