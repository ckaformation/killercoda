# Étape 1 — Installer kubeadm, kubelet et kubectl

Tu es connecté en root sur les deux machines : pas besoin de `sudo` devant les commandes.

## 0. Attendre la fin de la préparation automatique

Un script prépare `controlplane` et `node01` en arrière-plan depuis l'ouverture de ce scénario (containerd, reset kubeadm, nettoyage APT). Lance cette commande pour attendre sa fin avant de continuer — si elle met quelques secondes à répondre, c'est normal :

`/root/wait-for-prep.sh`{{exec}}

`containerd` est déjà installé et configuré sur les deux nœuds. Il te reste à installer les trois outils Kubernetes, **sur `controlplane` ET sur `node01`** :

- **kubeadm** : l'outil qui va créer/rejoindre le cluster ;
- **kubelet** : l'agent qui tourne sur chaque nœud et démarre les pods ;
- **kubectl** : le client en ligne de commande pour piloter le cluster.

On suit la procédure officielle : https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/

## Sur l'onglet `controlplane`

### 1. Ajouter le dépôt communautaire officiel des paquets Kubernetes (pkgs.k8s.io)

Depuis mars 2024, l'ancien dépôt `apt.kubernetes.io` n'existe plus : le dépôt officiel est désormais `pkgs.k8s.io`, un dépôt par version mineure de Kubernetes.

`mkdir -p -m 755 /etc/apt/keyrings`{{exec}}

`curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.36/deb/Release.key | gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg`{{exec}}

`echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.36/deb/ /' | tee /etc/apt/sources.list.d/kubernetes.list`{{exec}}

### 2. Installer kubeadm, kubelet et kubectl

`apt-get update`{{exec}}

`apt-get install -y kubelet kubeadm kubectl`{{exec}}

Empêche les mises à jour automatiques de ces paquets (une montée de version non maîtrisée de Kubernetes peut casser ton cluster) :

`apt-mark hold kubelet kubeadm kubectl`{{exec}}

### 3. Vérifier l'installation

`kubeadm version`{{exec}}

`kubectl version --client`{{exec}}

`kubelet --version`{{exec}}

## Sur l'onglet `node01`

Bascule sur l'onglet **`node01`** et répète exactement la même séquence de commandes que ci-dessus (points 1 à 3).

Une fois les deux nœuds équipés, tu es prêt(e) pour la suite : initialiser le cluster.
