# Static Pods : manifests, kubelet et crictl

Bienvenue ! Ce scénario porte sur les **static pods** — des pods gérés directement par le `kubelet` d'un nœud, à partir de fichiers manifestes locaux, sans passer par le scheduler ni le control-plane. C'est exactement ce mécanisme que `kubeadm` utilise pour démarrer `kube-apiserver`, `etcd`, `kube-scheduler` et `kube-controller-manager`.

## Ce qui est déjà en place

- Un cluster Kubernetes à deux nœuds fonctionnel : `controlplane` et `node01`.
- `crictl`, l'outil en ligne de commande du CRI (Container Runtime Interface), configuré pour parler à `containerd`, sur les deux nœuds.
- Un raccourci `k` (identique à `kubectl`), sur les deux nœuds.

## Ce que tu vas faire

1. Créer, à la main, un static pod basé sur une image simple (`nginx`) sur `node01` — **pas** un des static pods déjà utilisés par le control-plane — et vérifier son exécution à deux niveaux : côté Kubernetes (`kubectl`) et côté runtime de conteneurs (`crictl`).
2. Changer le `staticPodPath` de la configuration du kubelet **de node01**, et voir concrètement pourquoi les manifestes doivent impérativement se retrouver dans ce nouveau chemin.

> Pourquoi `node01` plutôt que `controlplane` ? `staticPodPath` est un réglage global du kubelet : le modifier affecte tout ce que ce kubelet gère comme static pods. Sur `controlplane`, ça inclurait `kube-apiserver`, `etcd`, `kube-scheduler` et `kube-controller-manager` — sur `node01`, il n'y a rien de tel à risquer : c'est un nœud worker, sans aucun composant du control-plane.

C'est parti !
