# Étape 1 — Explorer l'état actuel du cluster

`/root/wait-for-prep.sh`{{exec}}

## 1. Version du cluster

Depuis l'onglet `controlplane` :

`kubectl get nodes -o wide`{{exec}}

Les deux nœuds doivent être `Ready`, en version `v1.35.x`.

## 2. Version des outils locaux

`kubeadm version`{{exec}}

`kubectl version`{{exec}}

`kubelet --version`{{exec}}

## 3. Vérifier ce qui tourne dans kube-system

`kubectl get pods -n kube-system -o wide`{{exec}}

Tu devrais voir, entre autres, `etcd`, `kube-apiserver`, `kube-controller-manager`, `kube-scheduler`, `kube-proxy` et les pods Calico (`calico-node`).

## Pourquoi upgrader ?

Kubernetes ne supporte la mise à niveau que **d'une version mineure à la suivante** (par exemple 1.35 → 1.36, jamais 1.35 → 1.37 directement). Le principe général :

1. Upgrader le control-plane en premier.
2. Upgrader les workers ensuite, un par un.

C'est exactement ce qu'on va faire dans les étapes suivantes.
