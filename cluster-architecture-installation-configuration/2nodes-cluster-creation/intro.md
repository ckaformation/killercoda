# Créer un cluster Kubernetes from scratch avec kubeadm

Bienvenue ! Dans ce scénario, tu vas construire, à la main, un cluster Kubernetes à **deux nœuds** (`controlplane` + `node01`) avec `kubeadm`, en suivant la documentation officielle : https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/

## Ce qui est déjà en place

Cet environnement fournit deux machines, chacune accessible via son propre onglet de terminal : `controlplane` et `node01`.

Pour te concentrer sur les étapes spécifiques à kubeadm, ces deux machines ont été remises à une base "quasi vierge" avant que tu n'arrives :

- **containerd** est déjà installé et configuré sur les deux nœuds ; en revanche, les paquets **kubeadm**, **kubelet** et **kubectl** ont été désinstallés — ce sera l'objet de l'étape 1 ;
- le **swap est désactivé**, les **modules noyau** requis (`overlay`, `br_netfilter`) sont chargés, et les **paramètres sysctl** nécessaires au bridging réseau sont appliqués ;
- tout état Kubernetes préexistant (certificats, configuration, adhésion à un cluster) a été retiré via `kubeadm reset`, pour repartir de zéro.

## Ce que tu vas faire

1. Installer `kubeadm`, `kubelet` et `kubectl` sur `controlplane` et `node01`.
2. Initialiser le control-plane avec `kubeadm init`.
3. Installer un add-on réseau de pods (CNI).
4. Rattacher `node01` au cluster avec `kubeadm join`.
5. Vérifier que le cluster fonctionne en y déployant une application.

C'est parti !
