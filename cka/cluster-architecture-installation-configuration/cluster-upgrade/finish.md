# Bravo !

Tu viens de mettre à niveau un cluster Kubernetes kubeadm à deux nœuds, de v1.35.x à v1.36.x, sans temps d'arrêt significatif :

1. Changement du dépôt de paquets vers la nouvelle version mineure.
2. Upgrade de `kubeadm`, puis `kubeadm upgrade apply` sur le control-plane.
3. Drain, upgrade de `kubelet`/`kubectl`, uncordon sur le control-plane.
4. Upgrade de `kubeadm` puis `kubeadm upgrade node` sur le worker.
5. Drain, upgrade de `kubelet`/`kubectl`, uncordon sur le worker.

## Et pour un cluster avec plusieurs control-planes ?

Le principe reste le même, mais on utilise `kubeadm upgrade node` (au lieu de `kubeadm upgrade apply`) pour les control-planes additionnels, et `kubeadm upgrade plan` n'est nécessaire que sur le tout premier.

## Et le CNI (Calico) ?

Ce scénario n'a pas couvert la mise à niveau de Calico lui-même : c'est une démarche séparée, propre à chaque fournisseur de CNI, à traiter indépendamment de l'upgrade de Kubernetes.

## Pour aller plus loin

- Documentation officielle : https://kubernetes.io/docs/tasks/administer-cluster/kubeadm/kubeadm-upgrade/
- Changer de dépôt de paquets : https://kubernetes.io/docs/tasks/administer-cluster/kubeadm/change-package-repository/
- Upgrader des nœuds Linux : https://kubernetes.io/docs/tasks/administer-cluster/kubeadm/upgrading-linux-nodes/
