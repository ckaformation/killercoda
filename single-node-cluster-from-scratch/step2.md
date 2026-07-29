# Étape 2 — Initialiser le control-plane avec kubeadm init

## 1. Lancer kubeadm init

On précise :
- `--pod-network-cidr=10.244.0.0/16` : le CIDR attendu par l'add-on réseau Flannel qu'on installera à l'étape 3 ;
- `--cri-socket unix:///var/run/containerd/containerd.sock` : pour cibler explicitement containerd, sans ambiguïté possible avec un autre runtime présent sur la machine.

`sudo kubeadm init --pod-network-cidr=10.244.0.0/16 --cri-socket unix:///var/run/containerd/containerd.sock`{{exec}}

Cette commande prend une à deux minutes. Elle effectue les pre-flight checks, génère les certificats du cluster, démarre les composants du control-plane (`kube-apiserver`, `kube-scheduler`, `kube-controller-manager`, `etcd`) sous forme de pods statiques, puis démarre `CoreDNS`.

À la fin, `kubeadm init` affiche une commande `kubeadm join ...` : c'est celle que tu utiliserais pour rattacher un nœud worker à ce cluster. On y revient à la fin du scénario.

## 2. Configurer kubectl

`kubeadm init` a généré un fichier d'authentification administrateur dans `/etc/kubernetes/admin.conf`. Pour que `kubectl` l'utilise par défaut :

`mkdir -p $HOME/.kube`{{exec}}

`sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config`{{exec}}

`sudo chown $(id -u):$(id -g) $HOME/.kube/config`{{exec}}

## 3. Vérifier

`kubectl get nodes`{{exec}}

Le nœud apparaît, mais en état `NotReady`. C'est normal : aucun plugin réseau (CNI) n'est encore installé. On corrige ça à l'étape suivante.
