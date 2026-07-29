# Bravo !

Tu viens de construire un cluster Kubernetes from scratch, à la main, avec `kubeadm` :

1. Installation de `kubeadm`, `kubelet` et `kubectl` depuis le dépôt officiel `pkgs.k8s.io`.
2. Initialisation du control-plane avec `kubeadm init`.
3. Installation d'un plugin réseau CNI (Flannel).
4. Déploiement d'une application pour valider le cluster.

## Et pour ajouter un nœud worker ?

Sur un cluster à plusieurs machines, tu récupérerais la commande `kubeadm join ...` affichée à la fin de `kubeadm init` (ou régénérée avec `kubeadm token create --print-join-command` depuis le control-plane), puis tu l'exécuterais avec `sudo` sur chaque nouvelle machine. Cette machine aurait besoin, elle aussi, d'un containerd installé/configuré et des mêmes prérequis systèmes que ceux déjà préparés ici.

## Pour aller plus loin

- Documentation officielle kubeadm : https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/
- Administration d'un cluster kubeadm : https://kubernetes.io/docs/tasks/administer-cluster/kubeadm/
- Configuration du driver de cgroup : https://kubernetes.io/docs/tasks/administer-cluster/kubeadm/configure-cgroup-driver/
