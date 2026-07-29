# Créer un cluster Kubernetes from scratch avec kubeadm

Bienvenue ! Dans ce scénario, tu vas construire, à la main, un cluster Kubernetes mono-nœud avec `kubeadm`, en suivant la documentation officielle : https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/

## Ce qui est déjà en place sur cette VM

Pour te concentrer sur les étapes spécifiques à Kubernetes, cette machine a été préparée en amont, comme le ferait un administrateur système avant l'installation des outils Kubernetes :

- **containerd** est installé et configuré (driver de cgroup `systemd`, conformément à la documentation officielle) ;
- le **swap est désactivé** ;
- les **modules noyau** `overlay` et `br_netfilter` sont chargés ;
- les **paramètres sysctl** requis pour le bridging réseau sont appliqués :
  - `net.bridge.bridge-nf-call-iptables = 1`
  - `net.bridge.bridge-nf-call-ip6tables = 1`
  - `net.ipv4.ip_forward = 1`

Tu peux vérifier tout ça toi-même à tout moment avec, par exemple :

`systemctl status containerd`{{exec}}

## Ce que tu vas faire

1. Installer `kubeadm`, `kubelet` et `kubectl`.
2. Initialiser le control-plane avec `kubeadm init`.
3. Installer un add-on réseau de pods (CNI).
4. Vérifier que le cluster fonctionne en y déployant une application.

C'est parti !
