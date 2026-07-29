# Étape 1 — Installer kubeadm, kubelet et kubectl

`containerd` est déjà installé et configuré sur cette machine. Il te reste à installer les trois outils Kubernetes :

- **kubeadm** : l'outil qui va créer le cluster ;
- **kubelet** : l'agent qui tourne sur chaque nœud et démarre les pods ;
- **kubectl** : le client en ligne de commande pour piloter le cluster.

On suit la procédure officielle : https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/

## 1. Paquets nécessaires pour utiliser un dépôt APT via HTTPS

`sudo apt-get update`{{exec}}

`sudo apt-get install -y apt-transport-https ca-certificates curl gpg`{{exec}}

## 2. Ajouter le dépôt communautaire officiel des paquets Kubernetes (pkgs.k8s.io)

Depuis mars 2024, l'ancien dépôt `apt.kubernetes.io` n'existe plus : le dépôt officiel est désormais `pkgs.k8s.io`, un dépôt par version mineure de Kubernetes.

`sudo mkdir -p -m 755 /etc/apt/keyrings`{{exec}}

`curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.36/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg`{{exec}}

`echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.36/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list`{{exec}}

## 3. Installer kubeadm, kubelet et kubectl

`sudo apt-get update`{{exec}}

`sudo apt-get install -y kubelet kubeadm kubectl`{{exec}}

Empêche les mises à jour automatiques de ces paquets (une montée de version non maîtrisée de Kubernetes peut casser ton cluster) :

`sudo apt-mark hold kubelet kubeadm kubectl`{{exec}}

## 4. Vérifier l'installation

`kubeadm version`{{exec}}

`kubectl version --client`{{exec}}

`kubelet --version`{{exec}}

Une fois ces trois commandes exécutées sans erreur, tu es prêt(e) pour la suite : initialiser le cluster.
