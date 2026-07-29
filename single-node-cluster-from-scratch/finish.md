# Bravo !

Tu viens de construire un cluster Kubernetes à deux nœuds, from scratch, à la main, avec `kubeadm` :

1. Installation de `kubeadm`, `kubelet` et `kubectl` depuis le dépôt officiel `pkgs.k8s.io`.
2. Initialisation du control-plane avec `kubeadm init`.
3. Installation d'un plugin réseau CNI (Calico).
4. Rattachement du nœud `node01` avec `kubeadm join`.
5. Déploiement d'une application pour valider le cluster.

## Pour ajouter d'autres nœuds

Le principe reste le même que pour `node01` : préparer la machine (containerd, prérequis systèmes, paquets kubeadm/kubelet/kubectl), puis exécuter la commande `kubeadm join ...` (régénérable à tout moment avec `kubeadm token create --print-join-command` depuis le control-plane) sur la nouvelle machine.

## Pour aller plus loin

- Documentation officielle kubeadm : https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/
- Administration d'un cluster kubeadm : https://kubernetes.io/docs/tasks/administer-cluster/kubeadm/
- Ajout de nœuds Linux : https://kubernetes.io/docs/tasks/administer-cluster/kubeadm/adding-linux-nodes/
- Configuration du driver de cgroup : https://kubernetes.io/docs/tasks/administer-cluster/kubeadm/configure-cgroup-driver/
