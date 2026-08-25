# DaemonSet et hostPath

Bienvenue dans le dernier scénario du chapitre Workloads & Scheduling ! Un `DaemonSet` garantit un pod par nœud éligible — exactement ce qu'utilisent `kube-proxy` ou les plugins CNI. On va en créer un simple, qui écrit sur le disque local de chaque nœud via un volume `hostPath`.

## Ce qui est déjà en place

- Un cluster à deux nœuds : `controlplane` et `node01`, tous deux sans taint.
- Le namespace applicatif `hoth`.
- Un raccourci `k` (identique à `kubectl`).

## Ce que tu vas faire

1. Créer un `DaemonSet` (image `bash:5`) dans `hoth`, qui écrit en boucle un fichier sur un volume `hostPath` — un pod doit apparaître sur chacun des deux nœuds.
2. Poser un label sur `node01`, puis restreindre le `DaemonSet` à ce seul nœud via `nodeSelector`. Tu supprimeras ensuite le répertoire `hostPath` resté orphelin sur `controlplane`, pour constater qu'il ne revient jamais — la preuve que le DaemonSet n'y tourne plus.

C'est parti !
