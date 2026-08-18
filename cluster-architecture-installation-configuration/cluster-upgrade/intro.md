# Mettre à niveau un cluster Kubernetes avec kubeadm

Bienvenue ! Contrairement au scénario "from scratch", ici **Kubernetes est déjà installé et fonctionnel** sur les deux nœuds (`controlplane` + `node01`), en version **v1.35.x**. Ton objectif : le mettre à niveau vers **v1.36.x**, en suivant la procédure officielle : https://kubernetes.io/docs/tasks/administer-cluster/kubeadm/kubeadm-upgrade/

## Ce qui est déjà en place

- Un cluster kubeadm à 2 nœuds fonctionnel, en v1.35.x, avec Calico comme add-on réseau.
- `containerd`, `kubeadm`, `kubelet` et `kubectl` installés sur les deux nœuds.
- `kubectl` configuré sur `controlplane`.

## Ce que tu vas faire

1. Explorer l'état actuel du cluster.
2. Upgrader `kubeadm` puis le control-plane (`kubeadm upgrade apply`).
3. Upgrader `kubelet` et `kubectl` sur `controlplane`.
4. Upgrader `kubeadm` sur `node01` (`kubeadm upgrade node`).
5. Upgrader `kubelet` et `kubectl` sur `node01`, puis vérifier le cluster.

> Ce scénario porte sur la mise à niveau de Kubernetes lui-même (kubeadm/kubelet/kubectl). La mise à niveau de Calico (le CNI) est une démarche séparée, propre à chaque fournisseur de CNI, et n'est pas couverte ici.

C'est parti !
