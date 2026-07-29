# Étape 2 — Initialiser le control-plane avec kubeadm init

## 1. Lancer kubeadm init

`sudo kubeadm init --pod-network-cidr=192.168.0.0/16 --apiserver-advertise-address=172.30.1.2 --kubernetes-version=v1.36.2 --ignore-preflight-errors=NumCPU --ignore-preflight-errors=Mem`{{exec}}

### À quoi servent ces options ?

- **`--pod-network-cidr=192.168.0.0/16`** : réserve cette plage d'adresses IP au réseau des pods. C'est le CIDR par défaut attendu par **Calico**, l'add-on réseau qu'on installe à l'étape 3 — les deux valeurs doivent correspondre, sinon le réseau des pods ne fonctionnera pas.

- **`--apiserver-advertise-address=172.30.1.2`** : adresse IP que le `kube-apiserver` annonce aux autres composants (et aux futurs nœuds qui rejoindraient le cluster). Sans cette option, kubeadm choisit automatiquement une interface réseau, ce qui peut être ambigu sur une machine qui en a plusieurs. Sur l'environnement Killercoda, l'IP interne du premier hôte (`controlplane`) est fixe et vaut toujours `172.30.1.2` : on la fige explicitement pour être sûr que l'API server écoute sur la bonne interface.

- **`--kubernetes-version=v1.36.2`** : épingle la version exacte des composants du control-plane que kubeadm va déployer (`kube-apiserver`, `kube-controller-manager`, `kube-scheduler`, etc.), indépendamment de la version précise de `kubeadm`/`kubelet` installée par apt à l'étape 1. Utile pour reproduire un environnement de formation identique pour tout le monde.

- **`--ignore-preflight-errors=NumCPU`** : kubeadm vérifie par défaut qu'un nœud control-plane dispose d'au moins **2 CPU**, et arrête l'installation sinon (`[ERROR NumCPU]`). Cette option transforme cette erreur bloquante en simple avertissement — utile car les VM Killercoda peuvent disposer de moins de 2 CPU.

- **`--ignore-preflight-errors=Mem`** : de la même façon, kubeadm vérifie par défaut qu'au moins **1700 Mo de RAM** sont disponibles (`[ERROR Mem]`). Cette option ignore ce contrôle si la VM en dispose de moins.

Cette commande prend une à deux minutes. Elle effectue les pre-flight checks, génère les certificats du cluster, démarre les composants du control-plane (`kube-apiserver`, `kube-scheduler`, `kube-controller-manager`, `etcd`) sous forme de pods statiques, puis démarre `CoreDNS`.

À la fin, `kubeadm init` affiche une commande `kubeadm join ...` : c'est celle que tu utiliserais pour rattacher un nœud worker à ce cluster. On y revient à la fin du scénario.

## 2. Configurer kubectl

`kubeadm init` a généré un fichier d'authentification administrateur dans `/etc/kubernetes/admin.conf`. Pour que `kubectl` l'utilise par défaut :

`mkdir -p $HOME/.kube`{{exec}}

`sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config`{{exec}}

`sudo chown $(id -u):$(id -g) $HOME/.kube/config`{{exec}}

## 3. Vérifier

`kubectl get nodes`{{exec}}

Le nœud apparaît dans la liste. Il reste toutefois à installer un plugin réseau (CNI) : sans lui, les pods ne pourront pas communiquer entre eux. C'est l'objet de l'étape suivante.
