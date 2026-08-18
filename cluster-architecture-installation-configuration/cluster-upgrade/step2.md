# Étape 2 — Upgrader le control-plane (kubeadm)

> Reste sur l'onglet **`controlplane`** pour toute cette étape.

On suit la procédure officielle : https://kubernetes.io/docs/tasks/administer-cluster/kubeadm/kubeadm-upgrade/

## 1. Changer de dépôt de paquets

Le dépôt `pkgs.k8s.io` est organisé **par version mineure** : pour upgrader, il faut d'abord pointer vers le dépôt de la version cible (v1.36).

`sed -i 's/v1\.35/v1.36/' /etc/apt/sources.list.d/kubernetes.list`{{exec}}

`cat /etc/apt/sources.list.d/kubernetes.list`{{exec}}

## 2. Upgrader le paquet kubeadm

On repère automatiquement le dernier patch disponible dans la ligne v1.36 avec `apt-cache madison`, et on l'installe :

`apt-mark unhold kubeadm`{{exec}}

`apt-get update`{{exec}}

`apt-cache madison kubeadm`{{exec}}

`KUBEADM_VERSION=$(apt-cache madison kubeadm | awk '{print $3}' | sort -V | tail -1) && apt-get install -y kubeadm=$KUBEADM_VERSION`{{exec}}

`apt-mark hold kubeadm`{{exec}}

`kubeadm version`{{exec}}

## 3. Vérifier le plan d'upgrade

`kubeadm upgrade plan`{{exec}}

Cette commande vérifie que le cluster peut être mis à niveau et affiche les versions disponibles, ainsi qu'un tableau sur l'état des configurations des composants.

## 4. Appliquer l'upgrade

`KUBEADM_UPGRADE_TARGET=$(apt-cache madison kubeadm | awk '{print $3}' | sort -V | tail -1 | cut -d'-' -f1) && kubeadm upgrade apply -y v$KUBEADM_UPGRADE_TARGET`{{exec}}

Cette commande met à niveau les composants du control-plane (`kube-apiserver`, `kube-controller-manager`, `kube-scheduler`, `etcd`) ainsi que CoreDNS et kube-proxy. Elle prend une à deux minutes.

> Le CNI (Calico) n'est pas concerné par cette commande : sa mise à niveau, si besoin, suit un processus séparé propre à Calico, hors du périmètre de ce scénario.
